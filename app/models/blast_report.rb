class BlastReport < ActiveRecord::Base
  belongs_to :blast_run
  belongs_to :seqfeature
  serialize :report, Bio::Blast::Report
  delegate :blast_database, :to => :blast_run, :allow_nil => true
  delegate :taxon, :abbreviation, :name, :to => :blast_database, :allow_nil => true
  validates_presence_of :seqfeature
  validates_presence_of :blast_run
  has_paper_trail :skip => :report

end