class GeneModel < ActiveRecord::Base
  # created from an aggregation of seqfeature data
  # Dependent on Location, Seqfeature(Gene, CDS) and SeqfeatureQualifierValue(locus_tag)

  belongs_to :gene, :inverse_of => :gene_models
  belongs_to :mrna, :inverse_of => :gene_model
  belongs_to :cds, :inverse_of => :gene_model
  belongs_to :bioentry
  has_many :cds_locations, :class_name => "Location", :foreign_key => :seqfeature_id, :primary_key => :cds_id, :dependent  => :destroy
  has_many :mrna_locations, :class_name => "Location", :foreign_key => :seqfeature_id, :primary_key => :mrna_id, :dependent  => :destroy
  
  validates_presence_of :gene
  validates_presence_of :bioentry
  validates_uniqueness_of :rank, :scope => [:bioentry_id, :gene_id]
  
  accepts_nested_attributes_for :mrna
  accepts_nested_attributes_for :cds
  validates_associated :mrna
  validates_associated :cds
  before_validation :initialize_associations
  
  has_paper_trail :meta => {
    :parent_id => Proc.new { |gm| gm.bioentry_id },
    :parent_type => "Gene"
  }
  acts_as_api
  
  api_accessible :listing do |t|
    t.add :id
    t.add 'gene.id', :as => :gene_id
    t.add :locus_tag
    t.add :gene_name
    t.add :start_pos
    t.add :end_pos
    t.add :strand
    t.add :bioentry_id
    t.add 'bioentry.display_name', :as => :sequence_name
    t.add 'bioentry.version', :as => :sequence_version
    t.add 'bioentry.taxon.name', :as => :sequence_taxon
    t.add 'bioentry.taxon.species.name', :as => :sequence_species
  end
    
  # For use in limiting query results
  def self.seqfeature_types
    ["Gene","Cds","Mrna"]
  end
  
  def self.find_differential_variants(set_a, set_b=[])
    return [] if set_a.empty? #|| set_b.empty? Allow empty set_b
    query = GeneModel.scoped
    set_a.each do |exp_id|
      query = query.where("EXISTS (
        SELECT * FROM sequence_variants sv
        WHERE gene_models.bioentry_id = sv.bioentry_id
        AND start_pos <= sv.pos
        AND end_pos >= sv.pos
        AND sv.experiment_id = #{exp_id}
      )")
    end
    set_b.each do |exp_id|
      query = query.where("NOT EXISTS (
        SELECT * FROM sequence_variants sv
        WHERE gene_models.bioentry_id = sv.bioentry_id
        AND start_pos <= sv.pos
        AND end_pos >= sv.pos
        AND sv.experiment_id = #{exp_id}
      )")
    end
    return query
  end
  
  def as_json(*args)
    hsh = super(*args)
    hsh['gene_model']['sequence_name'] = bioentry.display_name
    hsh
  end
  
  def display_name
    variants==1 ? locus_tag.to_s : (locus_tag.to_s+"."+rank.to_i.to_s)
  end
  
  def variant_na_sequence(exp_id,window=0)
    return nil unless (v = Variant.find(exp_id))
    start = self.start_pos-window
    stop = self.end_pos+window
    v.get_sequence(start,stop,bioentry.id)
  end
  
  #TODO  move to CDS feature
  def na_sequence
    if(cds)
      seq = ""
      cds.locations.each do |l|
        seq += bioentry.biosequence.seq[l.start_pos-1, (l.end_pos-l.start_pos)+1]
      end
      return seq
    else
      return nil
    end
  end
  
  def variant_protein_sequence(exp_id,window=0)
    if(cds)
      if(cds.codon_start)
        frame = ((strand.to_i == 1) ? cds.codon_start.value.to_i : cds.codon_start.value.to_i+3)
        return Bio::Sequence::NA.new(variant_na_sequence(exp_id,window)).translate(frame, bioentry.taxon.genetic_code || 1)
      else
        return "Unknown codon start for cds"
      end
    else
      return nil
    end
  end
  
  def protein_sequence
    if(cds)
      if(cds.codon_start)
        frame = ((strand.to_i == 1) ? cds.codon_start.value.to_i : cds.codon_start.value.to_i+3)
        p =  Bio::Sequence::NA.new(na_sequence).translate(frame, bioentry.taxon.genetic_code || 1)
        p
      else
        return "Unknown codon start for cds"
      end
    else
      return nil
    end
  end
  
  def self.get_track_data(left,right,bioentry_id,max=5000)
    data=[]
    # select_all will return a hash without converting to ActiveRecord Objects. This is much faster than '.find'
    gene_models = ActiveRecord::Base.connection.select_all("SELECT gene_models.* 
      FROM gene_models 
      WHERE (
      gene_models.start_pos < #{right}
      AND gene_models.end_pos > #{left}
      AND gene_models.bioentry_id = #{bioentry_id})")
    
    if(gene_models.size < max)
      mrna_locations = ActiveRecord::Base.connection.select_all("SELECT g.id gene_model_id, g.strand, l.location_id, l.start_pos, l.end_pos 
        FROM gene_models g
        RIGHT OUTER JOIN location l ON l.seqfeature_id = g.mrna_id
        WHERE (
        g.start_pos < #{right} 
        AND g.end_pos > #{left}
        AND g.bioentry_id = #{bioentry_id})")
    else
      mrna_locations = [] 
    end
    
    if(gene_models.size < max)
      cds_locations = ActiveRecord::Base.connection.select_all("SELECT g.id gene_model_id, g.strand, l.location_id, l.start_pos, l.end_pos 
        FROM gene_models g
        RIGHT OUTER JOIN location l ON l.seqfeature_id = g.cds_id
        WHERE (
        g.start_pos < #{right} 
        AND g.end_pos > #{left}
        AND g.bioentry_id = #{bioentry_id})")
    else
      #only grab the first CDS location, we reached our max for gene models
      cds_locations = ActiveRecord::Base.connection.select_all("SELECT g.id gene_model_id, g.strand, l.location_id, l.start_pos, l.end_pos 
        FROM gene_models g
        RIGHT OUTER JOIN location l ON l.seqfeature_id = g.cds_id
        AND l.rank = 1
        WHERE (
        g.start_pos < #{right} 
        AND g.end_pos > #{left}
        AND g.bioentry_id = #{bioentry_id})
        AND g.rank = 1")
    end
          
    gene_models.each do |g|      
      data.push(
      [
         nil,
         g['id'].to_s,
         (g['strand'].to_i == 1 ? "+" : "-"),
         "gene",
         g['start_pos'].to_i,
         (g['end_pos'].to_i - g['start_pos'].to_i),
         ([]),
         "no product",#(f.product.nil? ? "-" : f.product.value),
         g['gene_name'].to_s,
         g['id'].to_s, #gene_id
         g['locus_tag'].to_s,
         g['end_pos'].to_i
      ])
    end
    mrna_locations.each do |l|
      data.push(
      [
         l['gene_model_id'].to_s,
         l['location_id'].to_s,
         (l['strand'].to_i == 1 ? "+" : "-"),
         "mRNA",
         l['start_pos'].to_i,
         (l['end_pos'].to_i - l['start_pos'].to_i),
         ([]),
         "",
         "",
         "",
         "",
         l['end_pos'].to_i
      ])
    end                   
    cds_locations.each do |l|
      data.push(
      [
         l['gene_model_id'].to_s,
         l['location_id'].to_s,
         (l['strand'].to_i == 1 ? "+" : "-"),
         "CDS",
         l['start_pos'].to_i,
         (l['end_pos'].to_i - l['start_pos'].to_i),
         ([]),
         "",
         "",
         "",
         "",
         l['end_pos'].to_i
      ])
    end
    
    return data
  end
  
  def self.get_canvas_data(left,right,bioentry_id,zoom=1,strand=1)
    @view_start=left
    @gui_zoom=zoom
    if(left > right || !left.kind_of?(Integer) || !right.kind_of?(Integer) || !bioentry_id.kind_of?(Integer))      
      return []
    end
    data=[]
    models = GeneModel.find(:all, :conditions=>"start_pos < #{right} AND end_pos > #{left} AND bioentry_id=#{bioentry_id} AND strand=#{strand}")
    models.each do |m|
      children=[]
      if(f = m.mrna)
        f.locations.each do |l|
          children << 
          {
            :id => l.id,
            :cls => "mRNA",
            :x => ((l.start_pos-@view_start)/@gui_zoom).floor,
            :x2 => ((l.end_pos-@view_start)/@gui_zoom).floor,
            :w => ((l.end_pos-l.start_pos)/@gui_zoom).floor
          }
        end
      end
      if(f = m.cds)
        f.locations.each do |l|
          children << 
          {
            :id => l.id,
            :cls => "CDS",
            :x => ((l.start_pos-@view_start)/@gui_zoom).floor,
            :x2 => ((l.end_pos-@view_start)/@gui_zoom).floor,
            :w => ((l.end_pos-l.start_pos)/@gui_zoom).floor
          }
        end
      end
      g = {
        :id  => m.id,
        :cls => "gene",
        :x => ((m.start_pos-@view_start)/@gui_zoom).floor,
        :w => ((m.end_pos-m.start_pos)/@gui_zoom).floor,
        :x2 => ((m.end_pos-@view_start)/@gui_zoom).floor,
        :children => children,
        :product  => "No Product",
        :gene => m.gene_name.to_s,
        :locus_tag => m.display_name,
        :oid => m.gene_id,
        :variants => m.variants
      }   
      data << g
    end
    return data
  end
  
  # Pull together the gene model information
  # Gene Models include:
  ## Gene Seqfeature
  ## Cds SeqFeature
  ## Mrna SeqFeature
  ##
  # Cds is sorted by protein_id then rank
  # Mrna is sorted by transcript_id then rank
  def self.generate(hsh={:destroy => false})
    #remove all gene models
    if hsh[:destroy]
      l = "Removing all existing Gene Models";puts l;logger.info "\n\n#{l}\n\n"
      self.delete_all
    end
    # Create Gene Models
    begin

      total_new_genes = Gene.count(:conditions => "NOT EXISTS (select id from gene_models where gene_id=#{Gene.primary_key})")
      l = "Creating #{total_new_genes} new genes: #{Time.now.strftime('%D %H:%M')}";puts l#;logger.info "\n\n#{l}\n\n"

      #check locus tags
      new_genes_with_locus = Gene.all(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where gene_id=seqfeature.#{Gene.primary_key}) AND term.name = 'locus_tag'").count
      if(new_genes_with_locus != total_new_genes)
        l = "#{total_new_genes - new_genes_with_locus} genes do not have a locus_tag! - checking for 'gene' annotations: #{Time.now.strftime('%D %H:%M')}";puts l
        new_genes_with_gene = Gene.all(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where gene_id=seqfeature.#{Gene.primary_key}) AND term.name = 'gene'").count
        if(new_genes_with_gene == total_new_genes)
          l = "Found 'gene' annotations for every Gene - checking cds and mrna: #{Time.now.strftime('%D %H:%M')}";puts l
          new_mrna_with_gene = Mrna.all(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where mrna_id=seqfeature.#{Mrna.primary_key}) AND term.name = 'gene'").count
          new_cds_with_gene = Cds.all(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where cds_id=seqfeature.#{Cds.primary_key}) AND term.name = 'gene'").count
          puts "mrna: #{new_mrna_with_gene}"
          puts "cds: #{new_cds_with_gene}"
          printf " Create locus_tag's from 'gene' annotations?(Y/n):"
          while (answer = gets.chomp)
            if(answer=='n'||answer=='Y')
              break
            else
              printf "choose 'Y' or 'n' : "
            end
          end
          if(answer=='Y')
            puts "Okay creating new locus_tag values"
            Gene.transaction do 
              ano_tag_ont_id = Ontology.find_or_create_by_name("Annotation Tags").id
              locus_tag_term_id = Term.find_or_create_by_name_and_ontology_id('locus_tag', ano_tag_ont_id).id
              puts "--Working on Genes"
              Gene.find_in_batches(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where gene_id=seqfeature.#{Gene.primary_key}) AND term.name = 'gene'") do |genes|
                genes.each do |g|
                  unless(g.gene)
                    raise "Attribute error - #{g} has no gene defined"
                  end
                  Gene.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id, term_id,value,rank)
                  VALUES(#{g.id},#{locus_tag_term_id},'#{g.gene}',1)")
                end
              end
              puts "--Working on CDS"
              Cds.find_in_batches(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where gene_id=seqfeature.#{Gene.primary_key}) AND term.name = 'gene'") do |cds|
                cds.each do |c|
                  if(c.gene)
                    Cds.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id, term_id,value,rank)
                    VALUES(#{c.id},#{locus_tag_term_id},'#{c.gene}',1)")
                  end
                end
              end
              puts "--Working on mRNA"
              Mrna.find_in_batches(:include => [:qualifiers => :term],:conditions => "NOT EXISTS (select id from gene_models where gene_id=seqfeature.#{Gene.primary_key}) AND term.name = 'gene'") do |mrna|
                mrna.each do |m|
                  if(m.gene)
                    Mrna.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id, term_id,value,rank)
                    VALUES(#{m.id},#{locus_tag_term_id},'#{m.gene}',1)")
                  end
                end
              end
              raise 'foobar'
            end#transaction
        else
          l = "Found #{new_genes_with_gene} gene annotations and #{new_genes_with_locus} locus_tag annotations - You need to Fix this!: #{Time.now.strftime('%D %H:%M')}";puts l
          raise "Format Error"
        end
        
      end
      
      gene_chunk = (total_new_genes/10.to_f).ceil
      new_gene_count = 0
      gene_model_count = 0      
      GeneModel.transaction do
        # new gene features
        Gene.find_in_batches(:batch_size=>250, :include => [[:qualifiers => :term],:locations], :conditions => "NOT EXISTS (select id from gene_models where gene_id=#{Gene.primary_key})") do |new_genes|        
          new_gene_locus = new_genes.map{|g|g.locus_tag.value}.join("', '")
          # cds lookup
          cds_by_locus = {}
          cds_ids = Cds.connection.select_all("Select seqfeature.seqfeature_id from seqfeature
          left outer join seqfeature_qualifier_value on seqfeature_qualifier_value.seqfeature_id = seqfeature.seqfeature_id
          left outer join term on term.term_id = seqfeature_qualifier_value.term_id
          where display_name = 'Cds'
          AND term.name = 'locus_tag'
          and value in('#{new_gene_locus}')
          and NOT EXISTS (select id from gene_models where cds_id=seqfeature.seqfeature_id)").map{|h| h['seqfeature_id'].to_i}.join("', '")
          Cds.find_in_batches(:include => [[:qualifiers => :term], :locations], :conditions => "seqfeature.seqfeature_id in('#{cds_ids}')") do |cds_batch|
            cds_batch.each do |cds|
              cds_by_locus[cds.locus_tag.value]||=[]
              cds_by_locus[cds.locus_tag.value] << [cds,cds.locations.map(&:start_pos).min,cds.locations.map(&:end_pos).max]
            end
          end
          # mrna lookup
          mrna_by_locus = {}
          mrna_ids = Mrna.connection.select_all("Select seqfeature.seqfeature_id from seqfeature
          left outer join seqfeature_qualifier_value on seqfeature_qualifier_value.seqfeature_id = seqfeature.seqfeature_id
          left outer join term on term.term_id = seqfeature_qualifier_value.term_id
          where display_name = 'Mrna'
          AND term.name = 'locus_tag'
          and value in('#{new_gene_locus}')
          and NOT EXISTS (select id from gene_models where mrna_id=seqfeature.seqfeature_id)").map{|h| h['seqfeature_id'].to_i}.join("', '")
          Mrna.find_in_batches(:include => [[:qualifiers => :term], :locations], :conditions => "seqfeature.seqfeature_id in('#{mrna_ids}')") do |mrna_batch|
            mrna_batch.each do |mrna|
              mrna_by_locus[mrna.locus_tag.value]||=[]
              mrna_by_locus[mrna.locus_tag.value] << [mrna,mrna.locations.map(&:start_pos).min,mrna.locations.map(&:end_pos).max]
            end
          end
          # sort by by transcript_id - protein_id then primary_key  - this seems to work for arabidopsis? It is not correctly order/paired in the file
          cds_by_locus.each_value do |v|
            v.sort!{|a,b| (a[0].protein_id || a[0].id) <=> (b[0].protein_id || b[0].id)}
          end
          mrna_by_locus.each_value do |v|
            v.sort!{|a,b| (a[0].transcript_id || a[0].id) <=> (b[0].transcript_id || b[0].id)}
          end         
          new_genes.each do |gene|          
            new_gene_count+=1         
            rank = 0          
            next if(gene.locations.empty?) # we can't use a gene if it doesn't even have locations!
        
            # CDS feature data - loop through each cds
            if(cds_features = cds_by_locus[gene.locus_tag.value])            
              variants = cds_features.size
              mrna_features = mrna_by_locus[gene.locus_tag.value]
              # new model for each cds
              cds_features.each_with_index do |cds_data, index|
                rank+=1
                gene_model = {}
                gene_model["cds_id"] = cds_data[0].id
                gene_model["transcript_id"] = cds_data[0].transcript_id.value if cds_data[0].transcript_id
                gene_model["variants"] = variants
                gene_model["rank"] = rank
            
                # mRNA feature data - Assuming mRNA will NOT be defined without CDS
                # data has already been sorted
                # NOTE: Added Fix for mrna that does NOT extend the full length of CDS. Yeast does this. 
                # Yeast does not have matching mRNA for this CDS i.e. gene(1..10); mrna(1..10); cds(1..10,15..20) Why, what does that mean?
                if(mrna_features)
                  begin      
                    gene_model["mrna_id"] = mrna_features[index][0].id          
                    gene_model["start_pos"] = [mrna_features[index][1],cds_data[1]].min  
                    gene_model["end_pos"] = [mrna_features[index][2],cds_data[2]].max
                    gene_model["protein_id"] = mrna_features[index][0].protein_id.value if mrna_features[index][0].protein_id
                  rescue
                    l = "Something went wrong adding mRNA data maybe cds <-> mrna counts aren't equal?\n#{$!}";puts l;logger.info "\n#{l}\n"
                  end
                else
                  gene_model["start_pos"] = cds_data[1]
                  gene_model["end_pos"] = cds_data[2]
                end
        
                # gene data
                gene_model["bioentry_id"] = gene.bioentry_id
                gene_model["locus_tag"] = gene.locus_tag.value
                gene_model["gene_name"] = gene.gene.value if gene.gene
                gene_model["gene_id"] = gene.id
                gene_model["strand"] = gene.locations.first.strand
                fast_insert(gene_model)
                gene_model_count +=1
              end       
            else
              # there was no CDS,  do we even want these?
              gene_model = {}
              gene_model["bioentry_id"] = gene.bioentry_id
              gene_model["locus_tag"] = gene.locus_tag.value
              gene_model["gene_name"] = gene.gene.value if gene.gene
              gene_model["gene_id"] = gene.id
              gene_model["start_pos"] = gene.locations.map(&:start_pos).min
              gene_model["end_pos"] = gene.locations.map(&:end_pos).max
              gene_model["strand"] = gene.locations.first.strand
              gene_model["rank"] = 1
              gene_model["variants"] = 1
              fast_insert(gene_model)
              gene_model_count +=1
             end
            if(new_gene_count%gene_chunk==0)
              printf("\t\t%i: %2.2f%\n",new_gene_count, ((new_gene_count/total_new_genes.to_f)*100).floor)
            end        
          end          
        end# End batch
      end#End Transaction      
      l = "\t...Created #{gene_model_count} gene models for #{new_gene_count} genes";puts l;logger.info "\n\n#{l}\n\n"
      l = "\t...Done: #{Time.now.strftime('%D %H:%M')}";puts l;logger.info "\n\n#{l}\n\n"
      return gene_model_count
    rescue
      puts "error creating Gene Models\n#{$!}"
      return false
    end
  end
  
  def initialize_associations
    logger.info "\n\nstart init gene model\n\n"
    # cds
      if(cds)
        cds.gene_model = self unless cds.gene_model
        cds.bioentry = self.bioentry
        self.transcript_id = self.cds.transcript_id
        self.start_pos = cds.locations.map(&:start_pos).min
        self.end_pos = cds.locations.map(&:end_pos).max
      end
      # mrna
      if(mrna)
        mrna.gene_model = self unless mrna.gene_model
        mrna.bioentry = self.bioentry
        self.protein_id = self.mrna.protein_id
        self.start_pos = mrna.locations.map(&:start_pos).min
        self.end_pos = mrna.locations.map(&:end_pos).max
      end    
      # rank
      if !self.rank || self.rank==0
        self.rank = ((self.gene.gene_models.map(&:rank).compact.max)||0) + 1
      end
      logger.info "\n\ndone set rank\n\n"
      # fall back position
      self.start_pos = gene.locations.map(&:start_pos).min unless self.start_pos
      self.end_pos = gene.locations.map(&:end_pos).max unless self.end_pos
      # attributes
      self.gene_name = self.gene.gene.value if self.gene.gene
      self.variants = self.gene.gene_models.size
      self.locus_tag = self.gene.locus_tag.value
      self.strand = self.gene.strand
      logger.info "\n\ndone init gene model\n\n"
      debugger
    end
end
# == Schema Information
#
# Table name: gene_models
#
#  transcript_id :string(4000)
#  protein_id    :string(4000)
#  id            :string(120)     primary key
#  variants      :decimal(, )
#  bioentry_id   :integer(38)     not null
#  locus_tag     :string(4000)
#  gene_name     :string(4000)
#  start_pos     :decimal(, )
#  end_pos       :decimal(, )
#  strand        :boolean(1)
#  gene_id       :integer(38)     not null
#  mrna_id       :integer(38)
#  cds_id        :integer(38)
#  rank          :decimal(, )
#

