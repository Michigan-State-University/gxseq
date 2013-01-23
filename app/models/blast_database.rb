class BlastDatabase < ActiveRecord::Base
  has_many :blast_reports
  has_many :taxon_versions, :through => :blast_runs
  has_many :blast_runs
  belongs_to :taxon
  validates_uniqueness_of :abbreviation
  validates_presence_of :abbreviation
  validates_presence_of :name
  has_attached_file :data, :path => ":rails_root/lib/data/blast_database/:exp_class/:exp_id/:id/:filename_with_ext" 
  validates_attachment_presence :data
end