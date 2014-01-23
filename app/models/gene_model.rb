# == Schema Information
#
# Table name: gene_models
#
#  bioentry_id   :integer
#  cds_id        :integer
#  end_pos       :integer
#  gene_id       :integer
#  gene_name     :string(255)
#  id            :integer          not null, primary key
#  locus_tag     :string(255)
#  mrna_id       :integer
#  protein_id    :string(255)
#  rank          :integer
#  start_pos     :integer
#  strand        :integer
#  transcript_id :string(255)
#  variants      :integer
#

class GeneModel < ActiveRecord::Base
  # de-normalization of seqfeature data
  # Dependent on Location, Seqfeature(Gene, CDS) and SeqfeatureQualifierValue(locus_tag). Incorporates Seqfeature(Mrna) if exists
  belongs_to :gene, :class_name => 'Biosql::Feature::Gene', :inverse_of => :gene_models
  belongs_to :mrna, :class_name => 'Biosql::Feature::Mrna', :inverse_of => :gene_model
  belongs_to :cds, :class_name => 'Biosql::Feature::Cds', :inverse_of => :gene_model
  belongs_to :bioentry, :class_name => 'Biosql::Bioentry'
  has_many :cds_locations, :class_name => "Biosql::Location", :foreign_key => :seqfeature_id, :primary_key => :cds_id, :dependent  => :destroy
  has_many :mrna_locations, :class_name => "Biosql::Location", :foreign_key => :seqfeature_id, :primary_key => :mrna_id, :dependent  => :destroy
  
  validates_presence_of :gene
  validates_presence_of :bioentry
  validates_uniqueness_of :rank, :scope => [:bioentry_id, :gene_id]
  
  accepts_nested_attributes_for :mrna
  accepts_nested_attributes_for :cds
  validates_associated :mrna
  validates_associated :cds
  before_validation :initialize_associations
  
  has_paper_trail :meta => {
    :parent_id => Proc.new { |gm| gm.gene_id },
    :parent_type => "Biosql::Feature::Gene"
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
  
  # Sunspot search definition
  searchable(:include => [[:bioentry => :assembly], [:cds => :product_assoc], [:mrna => :function_assoc], [:gene => [:product_assoc, :function_assoc]]]) do
    text :locus_tag_text, :stored => true do
      locus_tag
    end
    text :display_name_text, :stored => true do
      display_name
    end
    text :gene_name_text, :stored => true do 
      gene_name
    end
    text :function_text, :stored => true do
      function
    end
    text :product_text, :stored => true do
      product
    end
    string :protein_id
    string :transcript_id
    string :display_name
    string :gene_name
    string :locus_tag
    string :function
    string :product
    
    integer :id, :stored => true
    integer :start_pos, :stored => true
    integer :end_pos, :stored => true
    integer :strand, :stored => true
    integer :rank, :stored => true
    integer :assembly_id do
      bioentry.assembly_id
    end
    ## Sequence data
    # Taxon Version
    text :assembly_name_with_version_text, :stored => true do
     bioentry.assembly.name_with_version
    end
    # Species/Strain
    text :species_name_text, :stored => true do
     bioentry.assembly.species.scientific_name.name rescue 'No Species'
    end
    text :taxon_name_text, :stored => true do
     bioentry.assembly.taxon.scientific_name.name rescue 'No Taxon'
    end
    # Sequence
    text :sequence_name_text, :stored => true do
      bioentry.display_name
    end
    ## Filtering
    # Taxon Version
    string :assembly_name_with_version do
     bioentry.assembly.name_with_version
    end
    # Species/Strain
    string :species_name do
     bioentry.assembly.species.scientific_name.name rescue 'No Species'
    end
    string :taxon_name do
     bioentry.assembly.taxon.scientific_name.name rescue 'No Taxon'
    end
    # Sequence
    string :sequence_name do
      bioentry.display_name
    end
  end
  
  # Convenience method for Re-indexing a subset of features
  def self.reindex_all_by_id(gene_model_ids,batch_size=100)
    puts "Re-indexing #{gene_model_ids.length} gene models"
    progress_bar = ProgressBar.new(gene_model_ids.length)
    gene_model_ids.each_slice(100) do |id_batch|
      Sunspot.index GeneModel.includes([:bioentry => :assembly],[:cds => :product_assoc], [:mrna => :function_assoc], [:gene => [:product_assoc, :function_assoc]]).where{id.in(my{id_batch})}
      Sunspot.commit
      progress_bar.increment!(id_batch.length)
    end
    Sunspot.commit
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
  
  def function
    a = [gene.try(:function_assoc).try(:value),mrna.try(:function_assoc).try(:value)].compact
    a.empty? ? nil : a.join(';')
  end
  
  def product
    a = [gene.try(:product_assoc).try(:value),cds.try(:product_assoc).try(:value)].compact
    a.empty? ? nil : a.join(';')
  end
  
  def display_name
    variants==1 ? locus_tag.to_s : (locus_tag.to_s+"."+rank.to_i.to_s)
  end
  
  def display_data
    "#{locus_tag}.#{rank}:#{gene_name}: #{start_pos}..#{end_pos} #{strand == 1 ? '->' : '<-'}"
  end
  
  def cds_start
    cds.locations.sort{|a,b|a.start_pos<=>b.start_pos}.first.start_pos
  end
  
  def cds_end
    cds.locations.sort{|a,b|a.end_pos<=>b.end_pos}.last.end_pos
  end
  
  def variant_na_sequence(exp_id,opts={})
    return nil unless (v = Variant.find(exp_id))
    window = (opts[:window] || 0).to_i
    start = self.start_pos-window
    stop = self.end_pos+window
    seq = ""
    # start window
    if(window>0)
      seq += v.get_sequence(cds_start-window,cds_start-1,bioentry.id,opts[:sample],opts)
    end
    cds.locations.each do |l|
      seq += v.get_sequence(l.start_pos,l.end_pos,bioentry.id,opts[:sample],opts)
    end
    # end window
    if(window>0)
      seq += v.get_sequence(cds_end+1,cds_end+window,bioentry.id,opts[:sample],opts)
    end
    return seq
  end
  
  def na_sequence
    cds.try(:na_sequence)
  end
  
  def mrna_sequence
    mrna.try(:na_sequence)
  end
  
  def cds_sequence
    cds.try(:na_sequence)
  end
  
  def variant_protein_sequence(exp_id,opts={})
    if(cds)
      frame = (cds.codon_start.try(:value)||1).to_i
      frame += 3 if strand.to_i != 1
      return Bio::Sequence::NA.new(variant_na_sequence(exp_id,opts)).translate(frame, bioentry.taxon.genetic_code || 1)
    else
      return nil
    end
  end
  
  def protein_sequence
    if(cds)
      frame = (cds.codon_start.try(:value)||1).to_i
      frame += 3 if strand.to_i != 1
      return Bio::Sequence::NA.new(na_sequence).translate(frame, bioentry.taxon.genetic_code || 1)
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
      cds_locations = ActiveRecord::Base.connection.select_all("SELECT g.id gene_model_id, g.strand, l.location_id, l.start_pos, l.end_pos 
        FROM gene_models g
        RIGHT OUTER JOIN location l ON l.seqfeature_id = g.cds_id
        WHERE (
        g.start_pos < #{right} 
        AND g.end_pos > #{left}
        AND g.bioentry_id = #{bioentry_id})")
    else
      mrna_locations = []
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
         (g['end_pos'].to_i - g['start_pos'].to_i)+1,
         ([]),#styles unused
         "-",#product unused
         g['gene_name'].to_s,
         g['id'].to_s,
         g['locus_tag'].to_s,
         0
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
         (l['end_pos'].to_i - l['start_pos'].to_i)+1,
         ([]),
         "",
         "",
         "",
         "",
         1
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
         (l['end_pos'].to_i - l['start_pos'].to_i)+1,
         ([]),
         "",
         "",
         "",
         "",
         2
      ])
    end
    
    return data
  end
  
  def self.get_canvas_data(left,right,bioentry_id,zoom=1,strand=1,limit=nil)
    @view_start=left
    @gui_zoom=zoom
    if(left > right || !left.kind_of?(Integer) || !right.kind_of?(Integer) || !bioentry_id.kind_of?(Integer))      
      return []
    end
    data=[]
    models = GeneModel.includes(:mrna => :locations, :cds => :locations)
      .where("start_pos < #{right}")
      .where("end_pos > #{left}")
      .where("bioentry_id=#{bioentry_id}")
      .where("strand=#{strand}")
    models = models.limit(limit) if(limit)
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
  
  def initialize_associations
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
    # fall back position
    self.start_pos = gene.locations.map(&:start_pos).min unless self.start_pos
    self.end_pos = gene.locations.map(&:end_pos).max unless self.end_pos
    # attributes
    self.gene_name = self.gene.gene.try(:value)
    self.variants = self.gene.gene_models.size
    self.locus_tag = self.gene.locus_tag.try(:value)
    self.strand = self.gene.strand
  end
  # Removes all gene models in the db and then calls generate
  def self.generate!
    l = "Removing all existing Gene Models";puts l;logger.info "\n\n#{l}\n\n"
    self.delete_all
    self.generate
  end
  # Runs a generate method to create gene models in the database. Gene Models include:
  # Gene Seqfeature, Cds Seqfeature, Mrna Seqfeature
  def self.generate
    # Count the genes needing a model
    puts "There are #{genes_without_model.count} genes without Gene Models"
    return if genes_without_model.count==0
    # First Try Parent<->ID assoc
    puts "Trying Parent <-> ID lookup"
    generate_models_from_parent
    return if genes_without_model.count==0
    if(new_genes_with_locus.count == genes_without_model.count)
      # Try to locus generation
      generate_models_from_locus
    else
      puts "#{genes_without_model.count - new_genes_with_locus.count} genes do not have a locus_tag!"
      generate_from_prompt
    end
  end
  # asks the user for input on how to generate gene models.
  # passes execution to the chosen method
  def self.generate_from_prompt
    puts "What do you want to do:"
    puts "\t1 - Generate new locus tags from annotations"
    puts "\t2 - Generate gene models from Parent-Child annotations"
    puts "\t3 - Generate gene models from locus tags"
    puts "\t4 - Exit"
    user_choice = STDIN.gets.chomp.to_i
    case user_choice
    when 1
      generate_locus_annotations
      generate_from_prompt
    when 2
      generate_models_from_parent
    when 3
      generate_models_from_locus
    when 4
      return
    else
      puts "Invalid option, please try again"
      generate_from_prompt
    end
  end
  # TODO: GeneModel creation needs a refactor badly. Worst method in entire app. Perhaps use seqfeature relationship tables and avoid denormalization altogether
  # Uses locus_tag annotations in the database to create new gene models
  # Pull together the gene model information
  # Cds is sorted by protein_id then rank
  # Mrna is sorted by transcript_id then rank
  def self.generate_models_from_locus
    begin
      # start the Gene Model creation
      puts "Working on #{total_new_genes=new_genes_with_locus.count} Gene Models with locus: #{Time.now.strftime('%D %H:%M')}"
      new_gene_count = 0
      gene_model_count = 0
      progress_bar = ProgressBar.new(total_new_genes)
      GeneModel.transaction do
        # new gene features
        Biosql::Feature::Gene.find_in_batches(:batch_size=>250, :include => [[:qualifiers => :term],:locations], :conditions => "NOT EXISTS (select id from gene_models where gene_id=seqfeature_id)") do |new_genes|        
          new_gene_locus = new_genes.delete_if{|g|g.locus_tag.nil?}.map{|g|g.locus_tag.value}.join("', '")
          # cds lookup
          cds_by_locus = {}
          cds_ids = GeneModel.connection.select_all("Select seqfeature.seqfeature_id from seqfeature
          left outer join seqfeature_qualifier_value on seqfeature_qualifier_value.seqfeature_id = seqfeature.seqfeature_id
          left outer join term on term.term_id = seqfeature_qualifier_value.term_id
          where display_name = 'Cds'
          AND term.name = 'locus_tag'
          and value in('#{new_gene_locus}')
          and NOT EXISTS (select id from gene_models where cds_id=seqfeature.seqfeature_id)").map{|h| h['seqfeature_id'].to_i}.join("', '")
          Biosql::Feature::Cds.find_in_batches(:include => [[:qualifiers => :term], :locations], :conditions => "seqfeature.seqfeature_id in('#{cds_ids}')") do |cds_batch|
            cds_batch.each do |cds|
              cds_by_locus[cds.locus_tag.value]||=[]
              cds_by_locus[cds.locus_tag.value] << [cds,cds.min_start,cds.max_end]
            end
          end
          # mrna lookup
          mrna_by_locus = {}
          mrna_ids = GeneModel.connection.select_all("Select seqfeature.seqfeature_id from seqfeature
          left outer join seqfeature_qualifier_value on seqfeature_qualifier_value.seqfeature_id = seqfeature.seqfeature_id
          left outer join term on term.term_id = seqfeature_qualifier_value.term_id
          where display_name = 'Mrna'
          AND term.name = 'locus_tag'
          and value in('#{new_gene_locus}')
          and NOT EXISTS (select id from gene_models where mrna_id=seqfeature.seqfeature_id)").map{|h| h['seqfeature_id'].to_i}.join("', '")
          Biosql::Feature::Mrna.find_in_batches(:include => [[:qualifiers => :term], :locations], :conditions => "seqfeature.seqfeature_id in('#{mrna_ids}')") do |mrna_batch|
            mrna_batch.each do |mrna|
              mrna_by_locus[mrna.locus_tag.value]||=[]
              mrna_by_locus[mrna.locus_tag.value] << [mrna,mrna.min_start,mrna.max_end]
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
                gene_model["protein_id"] = cds_data[0].protein_id.try(:value)
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
                    gene_model["transcript_id"] = mrna_features[index][0].transcript_id.try(:value)
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
          end # end genes loop
        #update progress
        progress_bar.increment!(new_genes.length)
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
  
  def self.generate_models_from_parent
    # start the Gene Model creation
    begin
      # Setup query for genes with id_assoc
      new_genes_with_id = genes_without_model.with_qualifier('id')
      puts "Working on #{new_gene_count = new_genes_with_id.count} Genes without a model: #{Time.now.strftime('%D %H:%M')}"
      if new_gene_count == 0
        puts "No matching genes found"
        return false
      end
      mrna_gene_model_count = 0
      cds_gene_model_count = 0
      mrna_cds_gene_model_count = 0
      just_gene_count = 0
      # Load data into hashes for faster lookup
      # collect mrna ids with parent_assoc and keep id_assoc if present
      puts "Loading mRNA..."
      mrna_by_parent = {}
      mrna_query = mrna_without_model.includes(:locations).with_qualifier('parent')
      bar = ProgressBar.new(mrna_query.count)
      mrna_query.find_in_batches do |batch|
        batch.each do |mrna|
          mrna_by_parent[mrna.parent.value] ||= []
          mrna_by_parent[mrna.parent.value] << mrna
        end
        bar.increment!(batch.length)
      end
      # collect cds ids with parent_assoc
      puts "Loading CDS..."
      cds_by_parent = {}
      cds_query = cds_without_model.includes(:locations).with_qualifier('parent')
      bar = ProgressBar.new(cds_query.count)
      cds_query.find_in_batches do |batch|
        batch.each do |cds|
          cds_by_parent[cds.parent.value] ||= []
          cds_by_parent[cds.parent.value] << cds
        end
        bar.increment!(batch.length)
      end
      # Loop over new genes without gene models
      puts "Generating models..."
      bar = ProgressBar.new(new_gene_count)
      GeneModel.transaction do
        PaperTrail.enabled = false
        new_genes_with_id.includes(:locations).find_in_batches(:batch_size => 500) do |batch|
          batch.each do |new_gene|
            # skip items without locations
            next if new_gene.locations.empty?
            # base gene data
            new_gene_id = new_gene.id_sqv.value
            base_gene_model = {}
            base_gene_model[:bioentry_id] = new_gene.bioentry_id
            base_gene_model[:gene_name] = new_gene.gene.value if new_gene.gene
            base_gene_model[:gene_id] = new_gene.id
            base_gene_model[:strand] = new_gene.locations.first.strand
            # create locus if missing
            base_gene_model[:locus_tag]=new_gene.find_or_create_locus_tag(new_gene_id).value
            # If we have a child mrna or cds we create a gene model otherwise skip this gene
            if(mrna_list = mrna_by_parent[new_gene_id])
              # Create a gene model for each mrna
              mrna_list.each_with_index do |mrna,idx|
                # skip items without locations
                next if mrna.locations.empty?
                # Check mrna for locus and build if missing
                mrna.find_or_create_locus_tag(new_gene_id)
                # check for child cds and update counter
                if((cds = cds_by_parent[mrna.id_sqv.try(:value)].try(:first)) && ! cds.locations.empty?)
                  mrna_cds_gene_model_count+=1
                  cds.find_or_create_locus_tag(new_gene_id)
                else
                  mrna_gene_model_count+=1
                end
                # Setup the new gene model
                gene_model = base_gene_model
                gene_model[:cds_id] = cds.try(:id)
                gene_model[:protein_id] = cds.protein_id.try(:value)
                gene_model[:mrna_id] = mrna.id
                gene_model[:transcript_id] = mrna.transcript_id.try(:value)
                gene_model[:variants] = mrna_list.length
                gene_model[:rank] = idx
                gene_model[:start_pos] = [mrna.min_start,cds.try(:min_start)].compact.min
                gene_model[:end_pos] = [mrna.max_end,cds.try(:max_end)].compact.max
                fast_insert(gene_model)
              end
            elsif(cds_list = cds_by_parent[new_gene_id])
              cds_list.each_with_index do |cds,idx|
                next if cds.locations.empty?
                # check locus
                cds.find_or_create_locus_tag(new_gene_id)
                # update counter
                cds_gene_model_count+=1
                # Setup the gene model
                gene_model = base_gene_model
                gene_model[:cds_id] = cds.id
                gene_model[:protein_id] = cds.protein_id.try(:value)
                gene_model[:variants] = cds_list.length
                gene_model[:rank] = idx
                gene_model[:start_pos] = [cds.min_start,new_gene.min_start].min
                gene_model[:end_pos] = [cds.max_end,new_gene.max_end].max
                fast_insert(gene_model)
              end
            else
              just_gene_count+=1
            end
          end
          bar.increment!(batch.length)
        end
        PaperTrail.enabled=true
      end
      puts "\n\t...Done: #{Time.now.strftime('%D %H:%M')}"
      puts "\t#{mrna_cds_gene_model_count} gene models with mRNA and CDS created" if mrna_cds_gene_model_count>0
      puts "\t#{mrna_gene_model_count} gene models with mRNA created" if mrna_gene_model_count>0
      puts "\t#{cds_gene_model_count} gene models with CDS created" if cds_gene_model_count>0
      puts "\t#{just_gene_count} genes had no CDS or mRNA" if just_gene_count>0
      
      return mrna_cds_gene_model_count+mrna_gene_model_count+cds_gene_model_count
    rescue => e
      puts "error creating Gene Models\n#{$!}\n\n#{e.backtrace}"
      return false
    end
  end
  # Generates new locus annotations from existing data.
  # Expects Gene, mRNA and CDS to share a single qualifier such as NAME or ID
  # Returns a count of new genes with locus
  def self.generate_locus_annotations
    puts "There are #{genes_without_model.count} genes with no gene model."
    puts "#{new_genes_with_locus.count} have a locus tag"
    puts "Attempting to generate new locus tags. Defult is 'gene' ..."
    # check the gene annotation
    if(try_locus_generation_from_qualifier('gene'))
      puts "...Done"        
    else
      # No Good, probably need user intervention
      puts "What should we use to generate locus tags? type 'Name', 'ID', etc.. or 'exit' to skip:"
      while((new_term = STDIN.gets.chomp)!='exit')
        break if try_locus_generation_from_qualifier(new_term)
        puts "Try a new annotation or 'exit' to skip:"
      end
    end
    return new_genes_with_locus.count
  end
  # Report data on supplied qualifier term and prompt user for action
  # return true if the qualifier is chosen for update
  # return false if the qualifier is skipped
  def self.try_locus_generation_from_qualifier(qual_name)
    puts "checking for '#{qual_name}' annotations"
    new_gene_with_qual = genes_without_model.with_qualifier(qual_name)
    #Biosql::Feature::Gene.includes(:gene_models, :qualifiers => [:term]).where{gene_models.id == nil}.where{qualifiers.term.name == qual_name}
    new_mrna_with_qual = Biosql::Feature::Mrna.includes(:gene_model, :qualifiers => [:term]).where{gene_model.id == nil}.where{qualifiers.term.name == qual_name}
    new_cds_with_qual = Biosql::Feature::Cds.includes(:gene_model, :qualifiers => [:term]).where{gene_model.id == nil}.where{qualifiers.term.name == qual_name}
    puts "gene: #{g_cnt = new_gene_with_qual.count}, mrna: #{m_cnt = new_mrna_with_qual.count}, cds: #{c_cnt = new_cds_with_qual.count}"
    printf "Create locus_tag's from '#{qual_name}' annotations? (Y/n):"
    while (answer = STDIN.gets.chomp)
      if (answer=='n'||answer=='Y')
        break
      else 
        printf "choose 'Y' or 'n' : "
      end
    end
    if(answer=='Y')
      puts "Okay, creating new locus_tag values"
      GeneModel.transaction do 
        puts "--Working on Gene"
        Biosql::SeqfeatureQualifierValue.set_locus_using_qual(qual_name,new_gene_with_qual)
        puts "--Working on CDS"
        Biosql::SeqfeatureQualifierValue.set_locus_using_qual(qual_name,new_mrna_with_qual)
        puts "--Working on mRNA"
        Biosql::SeqfeatureQualifierValue.set_locus_using_qual(qual_name,new_cds_with_qual)
      end
      return true
    else
      puts "Okay, ignoring '#{qual_name}' annotations"
      return false
    end
  end
  
  def self.new_genes_with_locus
    new_genes_with_locus = genes_without_model.with_qualifier('locus_tag')
  end
  
  def self.genes_without_model
    Biosql::Feature::Gene.includes(:gene_models).where{gene_models.id == nil}
  end
  
  def self.mrna_without_model
    Biosql::Feature::Mrna.includes(:gene_model).where{gene_model.id == nil}
  end
  
  def self.cds_without_model
    Biosql::Feature::Cds.includes(:gene_model).where{gene_model.id == nil}
  end
end
