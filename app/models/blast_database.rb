class BlastDatabase < ActiveRecord::Base
  has_many :blast_reports
  has_many :taxon_versions, :through => :blast_runs
  has_many :blast_runs
  belongs_to :taxon
  validates_uniqueness_of :abbreviation
  validates_presence_of :abbreviation
  validates_presence_of :name
end