## Taxon Nested Set is NOT maintained during sequence load or default taxonomy load.
## It WILL be out of sync until you call - taxon::rebuild_nested_set
class Bio::Taxon < ActiveRecord::Base
  set_table_name "taxon"
  set_primary_key :taxon_id
  has_and_belongs_to_many :biodatabases
  belongs_to :parent, :class_name => "Taxon", :foreign_key => "parent_taxon_id"
  has_many :bioentries, :through => :assemblies, :order => :description
  has_many :taxon_names
  has_many :children, :class_name => "Taxon", :foreign_key => "parent_taxon_id"  
  has_one :scientific_name, :class_name => "TaxonName", :conditions => {:name_class => "scientific name"}
  has_one :taxon_genbank_common_name, :class_name => "TaxonName", :conditions=>"name_class = 'genbank common name'"
  # Version groups
  has_many :assemblies
  has_many :genomes
  has_many :transcriptomes
  scope :with_assemblies, lambda {includes{[assemblies,scientific_name]}.where{assemblies.id != nil}}
  scope :with_genomes, lambda {includes{[genomes,scientific_name]}.where{genomes.id != nil}}
  scope :with_transcriptomes, lambda {includes{[transcriptomes,scientific_name]}.where{transcriptomes.id != nil}}
  # Species groups - only successful if taxon is species
  has_many :species_assemblies, :class_name => "Assembly", :foreign_key => :species_id
  has_many :species_genomes, :class_name => "Genome", :foreign_key => :species_id
  has_many :species_transcriptomes, :class_name => "Transcriptome", :foreign_key => :species_id
  has_many :in_use_children, :through => :species_assemblies, :source => :taxon
  scope :with_species_assemblies, lambda {includes{[species_assemblies,scientific_name]}.where{species_assemblies.id != nil}}
  scope :with_species_genomes, lambda {includes{[species_genomes,scientific_name]}.where{species_genomes.id != nil}}
  scope :with_species_transcriptomes, lambda {includes{[species_transcriptomes,scientific_name]}.where{species_transcriptomes.id != nil}}
  
  ### Relations
  # Walk up the parent line until the root is reached
  # Returns an array of ancestors in reverse order [root,...,self]
  def ancestors(parents=[])
    if parent && parent != self
      parents.concat(parent.ancestors)
    end
    parents << self
  end
  # find or create the root of the tree
  def self.root
    if t = TaxonName.find_by_name('root')
      return t.taxon
    else
      return Taxon.where("parent_taxon_id == taxon_id OR parent_taxon_id is null").first || self.create_root
    end
  end
  # find or create the 'unknown' taxon
  def self.unknown
    if t = TaxonName.find_by_name('unidentified')
      return t.taxon
    else
      unknown = Taxon.create(:node_rank  => 'species', :genetic_code => '1', :mito_genetic_code  => '1', :non_ncbi => 1)
      unknown.taxon_names.create(:name => 'unidentified', :name_class => "scientific name")
      return unknown
    end
  end
  # Rebuild the Nested Set Tree
  def self.rebuild_nested_set(verbose)
    # Grab the entire taxon list and build a parent->children map
    puts "\t... collecting parent->child relationships\n" if verbose
    parent_child_map = Hash.new()
    ActiveRecord::Base.connection.select_all("SELECT taxon_id, parent_taxon_id FROM taxon ORDER BY ncbi_taxon_id").each do |node|
      parent_child_map[node["parent_taxon_id"].to_i] ||= [] 
      parent_child_map[node["parent_taxon_id"].to_i] << node["taxon_id"].to_i unless node["parent_taxon_id"].to_i == node["taxon_id"].to_i # skip if node points at self
    end
    # Nested set calculation
    begin
      puts "\t... rebuilding nested set left/right values\n" if verbose
      progress_bar = ProgressBar.new(Taxon.count*2) # left and right for each taxon
      Taxon.transaction do
        # start the recursive calculation on the root node
        update_nested_set(self.root.taxon_id.to_i,parent_child_map,Time.now,progress_bar)
      end
    rescue
      puts "**Error with Nested set:\n\t#{$!}"
      exit 0
    end
  end
  # convienence method for name
  def name
    scientific_name.name
  end
  # convienence method convert ids to string for json response
  def bioentry_id_string
    bioentries.sort{|a,b| a.id <=> b.id}.map(&:id).join(",")
  end
  # test if this taxon is a species
  def is_species?
    node_rank == 'species'
  end
  # look for the taxonomy species in ancestors otherwise return nil
  def species
    return self if is_species?
    ancestors.each do |t|
      if t.node_rank =='species'
        return t
      end
    end
    return nil
  end
  
  private 
  # create a new root
  def self.create_root
    root = Taxon.create(:node_rank  => 'no rank', :genetic_code => '1', :mito_genetic_code  => '1', :non_ncbi => 1)
    root.update_attribute(:parent_id,root.id) 
    root.taxon_names.create(:name => 'root', :name_class => "scientific name")
    root.taxon_names.create(:name => 'all', :name_class => "synonym")
    return root
  end
  # Recursive nested set calculation
  # depth first search sets left_value to nested_count on the way down, and right_value to nested_count on the way up
  def self.update_nested_set(current_id,parent_child_map,time,progress_bar,nested_count=0)
    progress_bar.increment!
    nested_count+=1  
    ActiveRecord::Base.connection.execute("Update Taxon SET left_value = #{nested_count} where taxon_id = #{current_id}")
    Array(parent_child_map[current_id]).each do |child_id|
      nested_count = update_nested_set(child_id.to_i,parent_child_map,time,progress_bar,nested_count)
    end  
    progress_bar.increment!
    nested_count+=1
    ActiveRecord::Base.connection.execute("Update Taxon SET right_value = #{nested_count} where taxon_id = #{current_id}")
    return nested_count
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

