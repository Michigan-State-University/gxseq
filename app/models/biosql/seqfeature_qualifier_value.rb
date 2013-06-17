class Biosql::SeqfeatureQualifierValue < ActiveRecord::Base
  set_table_name "seqfeature_qualifier_value"
  set_primary_keys :seqfeature_id, :term_id, :rank

  belongs_to :term
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature", :inverse_of => :qualifiers
  validates_presence_of :seqfeature
  validates_presence_of :term_id
  validates_presence_of :value
  validates_length_of :value, :within => 1..4000, :on => :create, :message => "Cannot exceed 4000 characters"
  validates_uniqueness_of :value, :scope => [:seqfeature_id, :term_id], :message => "Duplicate terms must be unique. This value already exists."
  # automatically set the rank
  before_validation :update_rank

  scope :with_ontology, lambda {|ont_id| includes(:term).where{term.ontology_id==my{ont_id}}}
  scope :with_term, lambda {|term_id| includes(:term).where{term.term_id == my{term_id}}}
  has_paper_trail :meta => {
    :parent_id => Proc.new { |l| (l.seqfeature.respond_to?(:gene_model) && l.seqfeature.gene_model) ? l.seqfeature.gene_model.gene_id : l.seqfeature.id },
    :parent_type => Proc.new { |l| (l.seqfeature.respond_to?(:gene_model) && l.seqfeature.gene_model) ? 'Gene' : l.seqfeature.class.name }
  }

  def <=>(o)
    self.value <=> o.value
  end

  def name
    "#{term.name}"
  end

  def text_id
    ids.to_s.gsub(/\,/,"_")
  end

  def to_s(allow_interpolate=true)
    value(allow_interpolate)
  end

  def display_data
    value
  end

  def self.db_xref_id
    @db_xref_id ||= (Biosql::Term.find_or_create_by_name_and_ontology_id("db_xref",Biosql::Ontology.find_or_create_by_name("Annotation Tags").id).id)
  end
  
  def self.set_locus_using_qual(qual_term,new_items_with_qual)
    locus_tag_term_id = Biosql::Term.locus_tag.id
    progress_bar = ProgressBar.new(new_items_with_qual.count)
    new_items_with_qual.find_in_batches do |features|
      features.each do |feature|
        next if feature.locus_tag
        if qual_value = feature.qualifiers.select{|q|q.term.name==qual_term}.first.try(:value)
          Biosql::SeqfeatureQualifierValue.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id, term_id,value,rank)
          VALUES(#{feature.id},#{locus_tag_term_id},'#{qual_value}',1)")
        end
      end
      progress_bar.increment!(features.length)
    end
  end
  
  def value(allow_interpolate=false)
    return super() unless allow_interpolate
    if(term_id == self.class.db_xref_id)
      val = super()
      dbname,dbid=val.split(":")
      if(dbname && dbid)
        "#{dbname}:<a href='#{Biosql::Dbxref::XREF_LINKS[dbname.underscore.to_sym]}#{dbid}' target=#>#{dbid}</a>"
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
        logger.info { "\n\nGetting :#{self.value}: rank\n\n" }
        self.rank = ((self.seqfeature.qualifiers.select{|q|q.term_id == self.term_id}.map(&:rank).compact.max)||0) + 1
        logger.info { "\n\nSet :#{self.value}: Rank to: #{self.rank}\n\n" }
      end
    end
  end

end

# == Schema Information
#
# Table name: seqfeature_qualifier_value
#
#  seqfeature_id :integer          not null
#  term_id       :integer          not null
#  rank          :integer          default(0), not null
#  value         :string(4000)     not null
#  created_at    :datetime
#  updated_at    :datetime
#

