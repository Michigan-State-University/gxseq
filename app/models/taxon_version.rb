class TaxonVersion < ActiveRecord::Base
  has_many :bioentries, :order => "name asc", :dependent => :destroy
  has_many :experiments
  #TODO experiment STI - can this be dynamic?
  has_many :chip_chips, :order => "experiments.name asc"
  has_many :chip_seqs, :order => "experiments.name asc"
  has_many :synthetics, :order => "experiments.name asc"
  has_many :variants, :order => "experiments.name asc"
  has_many :rna_seqs, :order => "experiments.name asc"
  has_many :re_seqs, :order => "experiments.name asc"
  has_many :blast_runs
  has_many :blast_databases, :through => :blast_runs
  belongs_to :taxon
  belongs_to :species, :class_name => "Taxon", :foreign_key => :species_id
  belongs_to :group
  validates_presence_of :taxon
  validates_presence_of :version
  validates_uniqueness_of :version, :scope => :taxon_id
  
  def reindex
    #bioentries
    bio_ids = bioentries.collect(&:id)
    Bioentry.reindex_all_by_id(bio_ids)
    #genemodels
    model_ids = GeneModel.where{bioentry_id.in my{bioentries}}.select("id").collect(&:id)
    GeneModel.reindex_all_by_id(model_ids)
    #seqfeatures
    feature_ids = Seqfeature.where{bioentry_id.in my{bioentries}}.select("seqfeature_id").collect(&:id)
    Seqfeature.reindex_all_by_id(feature_ids)
  end
  
  def name_with_version
    "#{name} ( #{version} )"
  end

  def name
    taxon.name
  end

  def has_expression?
    # check if any bioentry -> seqfeature has feature_counts
    bioentries.joins{seqfeatures.feature_counts}.count('feature_counts.count') > 0
  end

  def is_genome?
    false
  end

  # Collects the seqfeatures for each bioentry and indexes them
  # optionally accepts {:type => 'feature_type'} to scope indexing
  def index_features(opts={})
    terms = Term.seqfeature_tags.select("term_id as type_term_id")
    terms = terms.where{name==my{opts[:type]}} if opts[:type]
    feature_ids = Seqfeature.where{bioentry_id.in(my{self.bioentry_ids})}.where{type_term_id.in(terms)}.select("seqfeature_id").collect(&:id)
    Seqfeature.reindex_all_by_id(feature_ids)
  end

  def bioentry_ids
    Bioentry.select('bioentry_id').where{taxon_version_id == my{id}}
  end
end