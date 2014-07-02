class AddTaxonVersionIdToBioentry < ActiveRecord::Migration
  def self.up
    add_column :bioentry, :taxon_version_id, :integer
  end

  def self.down
    remove_column :bioentry, :taxon_version_id rescue puts "taxon_version_id column missing"
    remove_index :bioentry, :name => :bioentry_idx rescue puts "bioentry_idx missing"
  end
end