class AddTypeToTaxonVersions < ActiveRecord::Migration
  def self.up
    add_column :taxon_versions, :type, :string
  end

  def self.down
    remove_column :taxon_versions, :type
  end
end