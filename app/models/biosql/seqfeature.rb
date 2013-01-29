class Seqfeature < ActiveRecord::Base
  set_table_name "seqfeature"
  set_primary_key :seqfeature_id
  has_paper_trail :meta => {
    :parent_id => Proc.new { |seqfeature| (seqfeature.respond_to?(:gene_model) && seqfeature.gene_model) ? seqfeature.gene_model.gene_id : seqfeature.id },
    :parent_type => Proc.new { |seqfeature| (seqfeature.respond_to?(:gene_model) && seqfeature.gene_model) ? "Gene" : seqfeature.class.name }
  }
  set_sequence_name "SEQFEATURE_SEQ"
  set_inheritance_column :display_name
  belongs_to :bioentry
  belongs_to :type_term, :class_name => "Term", :foreign_key => "type_term_id"
  belongs_to :source_term, :class_name => "Term", :foreign_key =>"source_term_id"
  has_many :seqfeature_dbxrefs, :class_name => "SeqfeatureDbxref", :foreign_key => "seqfeature_id", :dependent  => :delete_all
  has_many :qualifiers, :include => :term, :class_name => "SeqfeatureQualifierValue",
    :order => "term.ontology_id desc,term.name,seqfeature_qualifier_value.rank", :dependent  => :delete_all,
    :inverse_of => :seqfeature, :after_remove => :update_assoc_mem
  has_many :object_seqfeature_paths, :class_name => "SeqfeaturePath", :foreign_key => "object_seqfeature_id", :dependent  => :delete_all
  has_many :subject_seqfeature_paths, :class_name => "SeqfeaturePath", :foreign_key => "subject_seqfeature_id"
  has_many :object_seqfeature_relationships, :class_name => "SeqfeatureRelationship", :foreign_key => "object_seqfeature_id", :dependent  => :delete_all
  has_many :subject_seqfeature_relationships, :class_name => "SeqfeatureRelationship", :foreign_key => "subject_seqfeature_id"
  has_many :locations, :dependent  => :delete_all

  #extensions
  has_many :feature_counts
  has_many :blast_reports
  has_many :favorite_seqfeatures, :foreign_key => :favorite_item_id
  has_many :favorite_users, :through => :favorite_seqfeatures, :source => :user
  # Define attributes to simplify eager_loading. _assoc suffix avoids name collision with dynamic qualifier methods
  # Use :qualifiers when including the entire attribute set. Use _assoc when including a small subset (1 or 2)
  has_one :product_assoc, :class_name => "SeqfeatureQualifierValue", :foreign_key => "seqfeature_id", :include => :term, :conditions => "term.name = 'product'"
  has_one :function_assoc, :class_name => "SeqfeatureQualifierValue", :foreign_key => "seqfeature_id", :include => :term, :conditions => "term.name = 'function'"
  # scope
  scope :with_locus_tag, lambda { |locus_tag|
    { :joins => [:qualifiers => [:term]], :conditions => "upper(seqfeature_qualifier_value.value) = '#{locus_tag.upcase}'"}
  }
  # validations
  accepts_nested_attributes_for :qualifiers, :allow_destroy => true, :reject_if => lambda { |q| (q[:id] && SeqfeatureQualifierValue.find(q[:id]).term.name =='locus_tag') || (q[:value].blank?) }
  accepts_nested_attributes_for :locations, :allow_destroy => true
  validates_presence_of :locations, :message => "Must have at least 1 location"
  validates_presence_of :bioentry
  validates_associated :qualifiers
  validates_associated :locations
  before_validation :initialize_associations
  # Update in memory assoc of delete. This is done for updates but not deletes TODO Investigate bug fixes in rails 3.1/3.2
  def update_assoc_mem(q)
    self.qualifiers -= [q]
  end
  # Sunspot search definition
  searchable(:include => [:bioentry,:type_term,:qualifiers,:feature_counts,:blast_reports,:locations,:favorite_users]) do
    text :locus_tag_text, :stored => true do
     locus_tag.value if locus_tag
    end
    text :description_text, :stored => true do
      description
    end
    text :full_description_text, :stored => true do
      full_description
    end
    text :taxon_version_name_with_version_text, :stored => true do
     bioentry.taxon_version.name_with_version
    end
    text :function_text, :stored => true do
      function
    end
    text :product_text, :stored => true do
      product
    end
    string :display_name
    string :description
    string :protein_id
    string :transcript_id
    string :function
    string :product
    string :locus_tag do
      locus_tag ? locus_tag.value : nil
    end
    string :sequence_name do
      bioentry.display_name
    end
    string :species_name do
      bioentry.species_name
    end
    string :version_name do
      bioentry.version_info
    end
    string :taxon_version_name_with_version do
     bioentry.taxon_version.name_with_version
    end
    integer :id, :stored => true
    integer :bioentry_id, :stored => true
    integer :type_term_id, :references => Term
    integer :source_term_id, :references => Term
    integer :strand, :stored => true
    integer :taxon_version_id do
      bioentry.taxon_version_id
    end
    integer :start_pos, :stored => true do
      min_start
    end
    integer :end_pos, :stored => true do
      max_end
    end
    integer :favorite_user_ids, :multiple => true, :stored => true
    
    # dynamic feature expression
    dynamic_float :normalized_counts, :stored => true do
      feature_counts.inject({}){|h,x| h["exp_#{x.experiment_id}"]=x.normalized_count;h}
    end
    dynamic_float :counts, :stored => true do
      feature_counts.inject({}){|h,x| h["exp_#{x.experiment_id}"]=x.count;h}
    end
    # dynamic blast reports
    dynamic_string :blast_def, :stored => true do
      blast_reports.inject({}){|hash,report| hash[report.blast_database.name+"_#{report.blast_run.id}"]=report.hit_def;hash}
    end
    dynamic_string :blast_acc, :stored => true do
      blast_reports.inject({}){|hash,report| hash[report.blast_database.name+"_#{report.blast_run.id}"]=report.hit_acc;hash}
    end
    dynamic_string :blast_id, :stored => true do
      blast_reports.inject({}){|hash,report| hash[report.blast_database.name+"_#{report.blast_run.id}"]=report.id;hash}
    end
    # Fake dynamic blast text - defined for 'every' blast_run on 'every' seqfeature
    # TODO: find another way to allow scoped blast_def full text search without searching all of the definitions
    BlastRun.all.each do |blast_run|
      string ("#{blast_run.blast_database.name}_#{blast_run.id}").to_sym, do
        #report = blast_reports.where("blast_run_id = #{blast_run.id}").select('hit_def').first
        report = blast_reports.select{|b| b.blast_run_id == blast_run.id }.first
        report ? report.hit_def : nil
      end
      text ("#{blast_run.blast_database.name}_#{blast_run.id}_text").to_sym, :stored => true do
        #report = blast_reports.where("blast_run_id = #{blast_run.id}").select('hit_def').first
        report = blast_reports.select{|b| b.blast_run_id == blast_run.id }.first
        report ? report.hit_def : nil
      end
    end
    # More fake dynamic text ... for custom ontologies and annotation
    Term.custom_ontologies.each do |ont|
      ont.terms.each do |ont_term|
        string "ont_#{ont.id}_#{ont_term.id}".to_sym do
          #a = self.qualifiers.with_term(ont_term.id).collect(&:value).join('; ')
          a = self.custom_qualifiers.select{|q| q.term.ontology_id == ont_term.id}.collect(&:value).join('; ')
          a.empty? ? nil : a
        end
        text "ont_#{ont.id}_#{ont_term.id}_text".to_sym, :stored => true do
          #a = self.qualifiers.with_term(ont_term.id).collect(&:value).join('; ')
          a = self.custom_qualifiers.select{|q| q.term.ontology_id == ont_term.id}.collect(&:value).join('; ')
          a.empty? ? nil : a
        end
      end
    end
  end

  ## CLASS METHODS

  # Use sunspot search to return a type_term_id facet for all seqfeatures with a given taxon_version_id
  def self.facet_types_with_expression_and_taxon_version_id(taxon_version_id)
    taxon_version = TaxonVersion.find_by_id(taxon_version_id)
    Seqfeature.search(:include => :feature_counts) do
      with(:taxon_version_id, taxon_version.id)
      any_of do
        taxon_version.experiments.each do |exp|
          dynamic(:normalized_counts) do
            without "exp_#{exp.id}", nil
          end
        end
      end
      facet(:type_term_id)
    end
  end
  # Convenience method for Re-indexing a subset of features
  def self.reindex_all_by_id(seqfeature_ids,batch_size=100)
    puts "Re-indexing #{seqfeature_ids.length} features"
    progress_bar = ProgressBar.new(seqfeature_ids.length)
    seqfeature_ids.each_slice(batch_size) do |id_batch|
      Sunspot.index Seqfeature.includes([:bioentry,:type_term,:qualifiers,:feature_counts,:blast_reports,:locations,:favorite_users, :gene_model])
        .where{seqfeature_id.in(my{id_batch})}
      Sunspot.commit
      progress_bar.increment!(id_batch.length)
    end
    Sunspot.commit
  end

  # return all seqfeatures with a single locus tag
  def self.find_all_by_locus_tag(locus="")
   find_all_with_locus_tags(Array(locus))
  end
  # return all seqfeatures matching a list of locus tags (limit list size to <= 999 if using oracle adapter)
  def self.find_all_with_locus_tags(locus)
    Seqfeature.joins(:qualifiers=>:term).where(:term=>{:name=>'locus_tag'}).where{qualifiers.value.in(locus)}.includes(:bioentry, :locations, :type_term, :qualifiers=>:term)
  end
  # return a list of seqfeatures overlapping a particular region on a bioentry
  # Optional types[] array will limit results to the supplied types
  def self.find_all_by_location(start=1, stop=2,bioentry_id=nil,types=[])
    features = Seqfeature.order('type_term_id')
      .includes(:locations, :type_term, [:qualifiers => [:term]])
      .where{(seqfeature.bioentry_id==my{bioentry_id}) & (location.start_pos < stop) & (location.end_pos > start)}
    unless types.empty?
      features = features.where{qualifiers.term.in(Array(types)) }
    end
    features
  end
  
  # returns terms that should not be indexed or displayed in search results
  def self.excluded_search_terms 
    ['translation','codon_start']
  end
  
  ## INSTANCE METHODS
  
  # generates a Seqfeature scope with all features having the same locus tag as self.
  # self will be included in the result
  def find_related_by_locus_tag
    return [self] if self.locus_tag.nil?
    return Seqfeature.find_all_by_locus_tag(self.locus_tag.value)
  end
  
  ## Display name for this feature. May be overriden in sub-class for custom types
  def label
    if locus_tag
      locus_tag.value
    else
      'no locus'
    end
  end
  # adds additional label information.
  # for sub-class. I.E  label=5 label_type = chromosome
  def label_type
    ''
  end
  # TODO: Refactor / Audit display_name,display_type,label,name etc.. too many variations
  def display_type
   self.type_term.name
  end

  def display_data
    "#{display_type}:"
  end

  # returns common description terms concatenated
  # gene function product gene_synonyms
  def description
  "#{gene.try(:value)} #{function.try(:value)} #{product.try(:value)} #{gene_synonym.try(:value)}"
  end
  # All non Genbank terms concatenated
  def custom_description
    Term.custom_ontologies.collect{|ont| ont.terms.collect{|term| self.qualifiers.select{|q| q.term_id == term.id} }}.flatten.compact.map(&:value).join('; ') 
  end
  # All Genbank terms concatenated
  def genbank_description
    annotation_qualifiers.map(&:value).join('; ') 
  end
  # All best blast hits concatenated
  def blast_description
    blast_reports.collect(&:hit_def).join('; ')
  end
  # All descriptions concatenated
  def full_description
    [search_qualifiers.map(&:value),blast_description].flatten.compact.join('; ')
  end
  # All attributes from the Genbank ontology
  def annotation_qualifiers
    qualifiers.select{|q| q.term.ontology_id == Term.ano_tag_ont_id}
  end
  # All annotation attributes for display / search
  def search_qualifiers
    qualifiers.select{|q| !Seqfeature.excluded_search_terms.include?(q.term.name) }
  end
  # All attributes from custom ontologies
  def custom_qualifiers
    qualifiers.select{|q| q.term.ontology_id != Term.ano_tag_ont_id}
  end
  ### SQV types - allows for quick reference through eager load of :qualifiers
  # NOTE: These could be converted to STI classes but the table has no primary key
  # single sqv
  ['chromosome','organelle','plasmid','mol_type', 'locus_tag','gene','gene_synonym','product','function','codon_start','protein_id','transcript_id'].each do |sqv|
  define_method sqv.to_sym do
    annotation_qualifiers.each do |q|
        if q.term&&q.term.name == sqv
           return q
        end
     end
     return nil
   end
  end
  # multiple sqvs
  ['db_xref','note'].each do |sqv|
    define_method (sqv+'s').to_sym do
      sqv_array = []
      qualifiers.each do |q|
        if q.term&&q.term.name == sqv
          sqv_array << q
        end
      end
      return sqv_array
    end
  end

  def strand
   self.locations.first ? self.locations.first.strand : 1
  end

  def min_start
   locations.map(&:start_pos).min
  end

  def max_end
   locations.map(&:end_pos).max
  end

  # TODO: remove duplicate na_seq method
  def na_seq
    na_sequence
  end
  # default na_seq; override for custom behavior (i.e. cds)
  def na_sequence
    seq = ""
    locations.each do |l|
      seq += bioentry.biosequence.seq[l.start_pos-1, (l.end_pos-l.start_pos)+1]
    end
    return seq
  end
  # default protein sequence, convert na
  def protein_sequence
    return Biosequence.to_protein(na_sequence,codon_start ? codon_start.value : 1,bioentry.taxon.genetic_code)
  end

  def length
    max_end - min_start
  end
  # return a genbank formatted location string
  def genbank_location
    text = ""
    if(locations.size > 1)
      text = "join(#{locations.collect(&:to_s).join(",")})"
    else
      text = locations.first.to_s
    end
    if(locations.first.strand.to_i == -1)
      text = "complement(#{text})"
    end
    return text
  end

  # return a genbank formatted entry ending with a newline
  # Name (start..end)
  #   qualifier=value
  #   qualifier2=value
  #
  # TODO: fix interpolate parameter. Should be options hash. 
  def to_genbank(allow_interpolate=true)
    text ="".ljust(6)+type_term.name.ljust(15)
    text += genbank_location.break_and_wrap_text(58,"\n",22,false)
    qualifiers.each do |q|
      text += ("/#{q.term.name}="+q.value(allow_interpolate)).break_and_wrap_text(58,"\n",22)
    end
    text+="\n"
    return text
  end
  
  # set rank and type_term before validation
  # creates a term for display_name if one cannot be found
  def initialize_associations
    if type_term_id.nil? && display_name
      seq_key_ont_id = Term.seq_key_ont_id
      self.type_term_id = Term.find_or_create_by_name_and_ontology_id(self.display_name,seq_key_ont_id).id
    end
    if !self.rank || self.rank==0 && self.bioentry_id && self.type_term_id
      self.rank = (self.bioentry.seqfeatures.where(:type_term_id => self.type_term_id).maximum(:rank)||0) + 1
      # TODO: Create test for this reverse assoc scenario, does inverse_of fix it?
      self.bioentry.seqfeatures.build(self)
    end
  end

  # TODO: Move track data to Decorator or Exhibit maybe?
  def self.get_track_data(left,right,bioentry_id,opts={})
    max = (opts[:max]||5000).to_i
    data = []
    x = 100
    # NOTE: all gene_model features are left in to allow mRNA only (transcriptome) features to display
    #features = Seqfeature.joins{[locations, bioentry]}.includes(:locations,:bioentry,:qualifiers).order("display_name").where("seqfeature.bioentry_id = #{bioentry_id} AND location.start_pos < #{right} AND location.end_pos > #{left} AND display_name not in ('#{GeneModel.seqfeature_types.push('Source').join("','")}')")
    features = Seqfeature.joins{[locations, bioentry]}.includes(:locations,:bioentry,:qualifiers).where("seqfeature.bioentry_id = #{bioentry_id} AND location.start_pos < #{right} AND location.end_pos > #{left} AND display_name != 'Source'")
    if (f = features).count > max
      # narrow the scope until we select a small enough result
      while f.count > max
        f = features
        f = f.where("MOD(#{right}-location.start_pos,#{max})<#{x}")
        x = (x/2).floor
      end
      features = features.where("MOD(#{right}-location.start_pos,#{max})<#{x}")
      #features = features.limit(500)
      features << opts[:feature] if opts[:feature]
    end
    logger.info "\n\n#{(features.size)}\nx:#{x}\n"
    features.each do |fea|
      data.push(
      [
        nil,
        fea.id.to_i,
        (fea.strand.to_i == 1 ? "+" : "-"),
        'feature_parent',
        fea.min_start,
        (fea.max_end - fea.min_start).to_s,
        "no product",
        "",
        fea.id.to_s,
        "",
        fea.max_end
      ])
      fea.locations.each do |loc|
        data.push(
        [
          fea.id,
          loc.id.to_i,
          (loc.strand.to_i == 1 ? "+" : "-"),
          fea.display_type,
          loc.start_pos.to_i,
          (loc.end_pos.to_i - loc.start_pos.to_i).to_s,
          "no product",
          "",
          fea.id.to_s,
          "",
          loc.end_pos.to_i
        ])
      end
    end

    return data
  end

end



# == Schema Information
#
# Table name: sg_seqfeature
#
#  oid            :integer(38)     not null, primary key
#  rank           :integer(9)      not null
#  display_name   :string(64)
#  ent_oid        :integer(38)     not null
#  type_trm_oid   :integer(38)     not null
#  source_trm_oid :integer(38)     not null
#  deleted_at     :datetime
#  updated_at     :datetime
#

