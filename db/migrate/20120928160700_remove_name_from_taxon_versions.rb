class RemoveNameFromTaxonVersions < ActiveRecord::Migration
  def self.up
    remove_column :taxon_versions, :name
  end

  def self.down
    add_column :taxon_versions, :name, :string
  end
end
