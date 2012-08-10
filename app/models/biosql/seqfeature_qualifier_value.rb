class SeqfeatureQualifierValue < ActiveRecord::Base
  set_table_name "seqfeature_qualifier_value"
  set_primary_keys :seqfeature_id, :term_id, :rank
  
  belongs_to :term
  belongs_to :seqfeature, :inverse_of => :qualifiers
  validates_presence_of :seqfeature
  validates_presence_of :term_id
  validates_presence_of :value
  validates_length_of :value, :within => 1..4000, :on => :create, :message => "Cannot exceed 4000 characters"
  validates_uniqueness_of :value, :scope => [:seqfeature_id, :term_id], :message => "Duplicate terms must be unique. This value already exists."
  # automatically set the rank
  before_validation :update_rank
  
  has_paper_trail :meta => {
    :parent_id => Proc.new { |l| l.seqfeature.respond_to?(:gene_model) ? l.seqfeature.gene_model.gene_id : l.seqfeature.id },
    :parent_type => Proc.new { |l| l.seqfeature.respond_to?(:gene_model) ? 'Gene' : l.seqfeature.class.name }
  }
  
  def <=>(o)
    self.value <=> o.value
  end
  
  def name
    term.name
  end
  
  def text_id
    ids.to_s.gsub(/\,/,"_")
  end

  def to_s
    value
  end
  
  def display_data
    value
  end
  
  def self.db_xref_id
    @db_xref_id ||= (Term.find_or_create_by_name_and_ontology_id("db_xref",Ontology.find_or_create_by_name("Annotation Tags").id).id)
  end
  
  def value(allow_interpolate=true)
    return super() unless allow_interpolate
    if(term_id == self.class.db_xref_id)
      val = super()
      dbname,dbid=val.split(":")
      if(dbname && dbid)
        "#{dbname}:<a href='#{Dbxref::XREF_LINKS[dbname.underscore.to_sym]}#{dbid}' target=#>#{dbid}</a>"
      else
        val
      end
    else
      super()
    end
  end
  
  protected
  
  def update_rank
    if !rank || rank==0
      if(self.seqfeature)
        self.rank = ((self.seqfeature.qualifiers.where(:term_id => self.term_id).map(&:rank).compact.max)||0) + 1
      end
      logger.info "\n\n#{"Just updated rank sqv"}\n\n"
    end
    
  end
  
end
# == Schema Information
#
# Table name: sg_seqfeature_qualifier_assoc
#
#  fea_oid    :integer(38)     not null
#  trm_oid    :integer(38)     not null
#  rank       :integer(3)      not null
#  value      :string(4000)
#  deleted_at :datetime
#  updated_at :datetime
#

