class BlastReport < ActiveRecord::Base
  belongs_to :blast_run
  belongs_to :seqfeature
  serialize :report, Bio::Blast::Report
  delegate :blast_database, :to => :blast_run, :allow_nil => true
  delegate :taxon, :filepath, :name, :description, :name_with_description, :to => :blast_database, :allow_nil => true
  validates_presence_of :blast_run_id
  has_paper_trail :skip => :report
  
end