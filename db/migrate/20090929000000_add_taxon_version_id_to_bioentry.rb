class AddTaxonVersionIdToBioentry < ActiveRecord::Migration
  def self.up
    add_column :bioentry, :taxon_version_id, :integer, :limit => 10, :null => false
  end

  def self.down
    remove_column :bioentry, :taxon_version_id
    remove_index :bioentry, :name => :bioentry_idx
  end
end