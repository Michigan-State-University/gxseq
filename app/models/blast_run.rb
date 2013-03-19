class BlastRun < ActiveRecord::Base
  belongs_to :blast_database
  belongs_to :assembly
  has_many :blast_reports, :dependent => :destroy
  serialize :parameters, Hash
  validates_presence_of :blast_database
  validates_presence_of :assembly
  
  def name
    "#{blast_database.name}"
  end
end