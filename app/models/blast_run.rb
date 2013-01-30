class BlastRun < ActiveRecord::Base
  belongs_to :blast_database
  belongs_to :taxon_version
  has_many :blast_reports, :dependent => :destroy
  serialize :parameters, Hash
  validates_presence_of :blast_database
  validates_presence_of :taxon_version
  
  def name
    "#{blast_database.name}"
  end
  def name_with_id
    "#{blast_database.name.gsub(/\s+/, "_")}_#{id}"
  end
end