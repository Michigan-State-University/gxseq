class Seqfeature < ActiveRecord::Base
  set_table_name "seqfeature"
  set_primary_key :seqfeature_id
  has_paper_trail :meta => {
    :parent_id => Proc.new { |seqfeature| seqfeature.respond_to?(:gene_model) ? seqfeature.gene_model.gene_id : '' },
    :parent_type => Proc.new { |seqfeature| seqfeature.respond_to?(:gene_model) ? "Gene" : '' }
  }
  set_sequence_name "SEQFEATURE_SEQ"
  set_inheritance_column :display_name
  belongs_to :bioentry
  belongs_to :type_term, :class_name => "Term", :foreign_key => "type_term_id"
  belongs_to :source_term, :class_name => "Term", :foreign_key =>"source_term_id"
  has_many :seqfeature_dbxrefs, :class_name => "SeqfeatureDbxref", :foreign_key => "seqfeature_id", :dependent  => :delete_all
  has_many :qualifiers, :include => :term, :class_name => "SeqfeatureQualifierValue", :order => "term.name,seqfeature_qualifier_value.rank", :inverse_of => :seqfeature, :dependent  => :delete_all

  has_many :object_seqfeature_paths, :class_name => "SeqfeaturePath", :foreign_key => "object_seqfeature_id", :dependent  => :delete_all
  has_many :subject_seqfeature_paths, :class_name => "SeqfeaturePath", :foreign_key => "subject_seqfeature_id"
  has_many :object_seqfeature_relationships, :class_name => "SeqfeatureRelationship", :foreign_key => "object_seqfeature_id", :dependent  => :delete_all
  has_many :subject_seqfeature_relationships, :class_name => "SeqfeatureRelationship", :foreign_key => "subject_seqfeature_id"
  
  has_many :locations, :dependent  => :delete_all
  scope :with_locus_tag, lambda { |locus_tag| 
    { :joins => [:qualifiers => [:term]], :conditions => "upper(seqfeature_qualifier_value.value) = '#{locus_tag.upcase}'"}
  }
  accepts_nested_attributes_for :qualifiers, :allow_destroy => true, :reject_if => lambda { |q| (q[:id] && !q[:id].match(/\d,\d,\d/)) || (q[:id] && SeqfeatureQualifierValue.find(q[:id]).term.name =='locus_tag') }
  accepts_nested_attributes_for :locations, :allow_destroy => true
  validates_presence_of :locations, :message => "Must have at least 1 location"
  validates_presence_of :bioentry
  validates_associated :qualifiers
  validates_associated :locations
  
  before_validation :initialize_associations
  
  searchable(:include => [:bioentry,:type_term,:qualifiers]) do
    
    text :qualifier_values, :stored => true do
      qualifiers.map{|q|q.value}
    end
    # TODO: convert locus_tag to text
    # text :locus_tag, :stored => true do
    #  locus_tag.value if locus_tag
    # end
    string :display_name
    string :locus_tag, :stored => true do
      locus_tag.value if locus_tag
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
    integer :type_term_id, :references => Term
  end
  
  
  #TODO : convert this to a real class with STI on the SQV table
  #has_many :notes, :class_name => "SeqfeatureQualifierValue", :order => "rank", :conditions => "trm_oid = #{Term.find_by_name("note").id}"

  ## CLASS METHODS
  #  Override STI. If the type is not defined, create a class for it.
  def self.find_sti_class(type_name)
    begin
      super(type_name)
    rescue ActiveRecord::SubclassNotFound
      logger.error "\n\nEncountered Unknown Seqfeature type: #{type_name}\n\n"
      Object.const_set(type_name.gsub(/\W/,"_").gsub(/_+/,"_"),Class.new(Seqfeature))
    end
  end
  
  def self.find_all_by_locus_tag(locus="")
    self.find(:all, 
    :include => [:bioentry, :locations, :type_term, [:qualifiers => [:term]]], 
    :order => "seqfeature.seqfeature_id ASC", 
    :conditions => ["exists (
       SELECT sqv.seqfeature_id
       FROM seqfeature_qualifier_value sqv, term t 
       WHERE sqv.seqfeature_id = seqfeature.seqfeature_id
       AND sqv.term_id = t.term_id 
       AND t.name = 'locus_tag' 
       AND UPPER(sqv.value) = ?)", locus.upcase])
  end

  def self.find_all_by_location(start=1, stop=2,bioentry_id=nil,types=[])
   if types.empty?
    self.find(:all, 
    :include => [:locations, :type_term, [:qualifiers => [:term]]],
    :order => "type_term_id",
    :conditions => [
      "seqfeature.bioentry_id = ?
      AND location.start_pos < ?
      AND location.end_pos > ?",bioentry_id,stop,start
    ])
    else
      self.find(:all, 
      :include => [:locations, :type_term, [:qualifiers => [:term]]],
      :order => "type_term_id",
      :conditions => [
        "terms_seqfeature_qualifier_.name in (?)
        AND seqfeature.bioentry_id = ?
        AND location.start_pos < ?
        AND location.end_pos > ?",types,bioentry_id,stop,start
      ])
    end       
  end

  ## INSTANCE METHODS
  def find_related_by_locus_tag
    return [self] if self.locus_tag.nil?
    return Seqfeature.find_all_by_locus_tag(self.locus_tag.value)
  end

  def display_type
   self.type_term.name
  end
  
  def display_data
    "#{type}:"
  end
  ### SQV types - allows for quick reference through eager load of :qualifiers
  ['chromosome','organelle','plasmid','mol_type', 'locus_tag','gene','product','codon_start','protein_id','transcript_id'].each do |sqv|
  define_method sqv.to_sym do
    qualifiers.each do |q|
        if q.term.name == sqv
           return q
        end
     end
     return nil
   end
  end

  def db_xrefs
   n = []
   qualifiers.each do |q|
     if q.term.name == 'db_xref'
       n<< q
     end
   end
   return n    
  end

  def notes
   n = []
   qualifiers.each do |q|
     if q.term.name == 'note'
       n<< q
     end
   end
   return n  
  end

  def strand
   self.locations ? self.locations.first.strand : 1
  end

  def min_start
   locations.map(&:start_pos).min
  end

  def max_end
   locations.map(&:end_pos).max
  end      
  # default na_seq override for custom behavior (i.e. cds)
  def na_seq
   bioentry.biosequence.seq[min_start-1, (max_end-min_start)+1]
  end
   
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
  
  def to_genbank
    text ="\n".ljust(6)+type_term.name.ljust(15)
    text += genbank_location.break_and_wrap_text(58,"\n",22,false)
    qualifiers.each do |q|
      text += ("/#{q.term.name}="+q.value).break_and_wrap_text(58,"\n",22)
    end
    return text
  end

  def initialize_associations
    #qualifiers.each{|q|q.seqfeature = self}
    if type_term_id.nil? && display_name
      seq_key_ont_id = Ontology.find_or_create_by_name("SeqFeature Keys").id
      self.type_term_id = Term.find_or_create_by_name_and_ontology_id(self.display_name,seq_key_ont_id).id
    end
    if !self.rank || self.rank==0 && self.bioentry_id && self.type_term_id
      self.rank = (self.bioentry.seqfeatures.where(:type_term_id => self.type_term_id).maximum(:rank)||0) + 1
      self.bioentry.seqfeatures.build(self)
    end
  end
  
  def self.get_track_data(left,right,bioentry_id)
    data = []
    features = Seqfeature.joins{[locations, bioentry]}.includes(:locations,:bioentry,:qualifiers).order("display_name").where("seqfeature.bioentry_id = #{bioentry_id} AND location.start_pos < #{right} AND location.end_pos > #{left} AND display_name not in ('#{GeneModel.seqfeature_types.push('Source').join("','")}')")

    features.each do |fea|
      data.push(
      [
        nil, 
        fea.id.to_i,
        (fea.strand.to_i == 1 ? "+" : "-"),
        'feature_parent',#fea.display_name.underscore,
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
          fea.display_name.underscore,
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

