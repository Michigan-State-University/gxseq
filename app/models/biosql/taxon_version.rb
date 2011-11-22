class TaxonVersion < ActiveRecord::Base
  has_many :bioentries
  has_many :experiments
  #TOSO experiment STI - can this be dynamic?
  has_many :chip_chips
  has_many :chip_seqs
  has_many :synthetics
  has_many :variants
  
  belongs_to :taxon
  belongs_to :species, :class_name => "Taxon", :foreign_key => :species_id
  
  validates_presence_of :taxon
  validates_presence_of :version
  validates_uniqueness_of :version, :scope => :taxon_id
  
  def name_with_version
    "#{name} ( #{version} )"
  end
  
end