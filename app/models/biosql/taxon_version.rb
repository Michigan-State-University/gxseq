class TaxonVersion < ActiveRecord::Base
  has_many :bioentries, :order => "name asc"
  has_many :experiments
  #TOSO experiment STI - can this be dynamic?
  has_many :chip_chips, :order => "name asc"
  has_many :chip_seqs, :order => "name asc"
  has_many :synthetics, :order => "name asc"
  has_many :variants, :order => "name asc"
  
  belongs_to :taxon
  belongs_to :species, :class_name => "Taxon", :foreign_key => :species_id
  
  validates_presence_of :taxon
  validates_presence_of :version
  validates_uniqueness_of :version, :scope => :taxon_id
  
  def name_with_version
    "#{name} ( #{version} )"
  end
  
end