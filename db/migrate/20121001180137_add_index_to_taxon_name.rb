class AddIndexToTaxonName < ActiveRecord::Migration
  def self.up
    add_index :taxon_name, [:name], :name => :taxon_name_idx2
  end

  def self.down
    remove_index :taxon_name, :name => :taxon_name_idx2
  end
end