class BlastDatabase < ActiveRecord::Base
  has_many :blast_reports
  has_many :assemblies, :through => :blast_runs
  has_many :blast_runs
  belongs_to :taxon
  belongs_to :group
  validates_presence_of :name
  def name_with_description
    "#{name} - #{description}"
  end
end