class Taxon < ActiveRecord::Base
  set_table_name "taxon"
  set_primary_key :taxon_id
  belongs_to :parent, :class_name => "Taxon", :foreign_key => "parent_taxon_id"
  has_many :bioentries, :through => :taxon_versions, :order => :description
  has_many :taxon_names
  has_many :taxon_versions
  has_many :species_versions, :class_name => "TaxonVersion", :foreign_key => :species_id #only valid if taxon is species
  has_many :children, :class_name => "Taxon", :foreign_key => "parent_taxon_id"  
  #has_many :ancestors, :class_name => "Taxon", :foreign_key => :taxon_id, :conditions => %q(#{left_value} BETWEEN left_value AND right_value)
  has_one :scientific_name, :class_name => "TaxonName", :conditions => {:name_class => "scientific name"}
  has_one :taxon_genbank_common_name, :class_name => "TaxonName", :conditions=>"name_class = 'genbank common name'"
  #has_one :species, :class_name => "Taxon", :foreign_key => :taxon_id, :conditions => %q(#{left_value} BETWEEN left_value AND right_value AND node_rank = 'species')

  #extensions
  EXPERIMENT_SQL = %q(select e.* from taxon t left outer join bioentry b on b.taxon_id = t.taxon_id 
    left outer join bioentries_experiments be on be.bioentry_id = b.bioentry_id 
    left outer join experiments e on e.id = be.experiment_id where t.taxon_id = #{id} )
  # using finder sql works, although I don't like it
  has_many :experiments, :finder_sql => ("#{EXPERIMENT_SQL}")
  has_many :chip_seqs, :finder_sql => ("#{EXPERIMENT_SQL} and e.type =  'ChipSeq'")
  has_many :chip_chips, :finder_sql => ("#{EXPERIMENT_SQL} and e.type =  'ChipChip'")
  has_many :synthetics, :finder_sql => ("#{EXPERIMENT_SQL} and e.type =  'Synthetic'")
  has_many :variants, :finder_sql => ( "#{EXPERIMENT_SQL} and e.type =  'Variant'")
  
  scope :in_use, :conditions => "#{Taxon.primary_key} in (select taxon_id from #{TaxonVersion.table_name})"
  scope :in_use_species, :joins => "inner join taxon_versions on taxon_versions.species_id = taxon.taxon_id", :select => 'distinct (taxon.taxon_id), parent_taxon_id, left_value, right_value, ncbi_taxon_id'
  ### Relations
  
  # def self.in_use_species
  #   #between_where = Taxon.joins(:bioentries).select("distinct #{Taxon.table_name}.left_value").map(&:left_value).collect{|left| "(#{left} BETWEEN left_value AND right_value)"}.join(" OR ")
  #   #Taxon.where(between_where).where(:node_rank => 'species').includes(:taxon_names, :scientific_name).order(:scientific_name => :name)
  # end
  
  def ancestors
    Taxon.where("#{left_value || -1} BETWEEN left_value AND right_value").order(:left_value)
  end
  
  ###
  
  def name
    scientific_name.name
  end
  
  def versions
    bioentries.select("distinct(version), description").map(&:version).uniq
  end
  
  def bioentry_id_string
    bioentries.sort{|a,b| a.id <=> b.id}.map(&:id).join(",")
  end
  

  
  def is_species?
    node_rank =='species'
  end
  
  def species
    return self if is_species?
    ancestors.each do |t|
      if t.node_rank =='species'
        return t
      end
    end
    return nil
  end
  
  # expects a species to call this method
  def in_use_children
    species_versions.joins(:taxon).map(&:taxon).uniq
  end
  
end



# == Schema Information
#
# Table name: sg_taxon
#
#  oid               :integer(38)     not null, primary key
#  ncbi_taxon_id     :integer(38)
#  node_rank         :string(32)
#  genetic_code      :integer(2)
#  mito_genetic_code :integer(2)
#  left_value        :integer(38)
#  right_value       :integer(38)
#  tax_oid           :integer(38)
#  deleted_at        :datetime
#  updated_at        :datetime
#

