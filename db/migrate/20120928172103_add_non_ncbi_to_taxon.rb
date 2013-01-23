class AddNonNcbiToTaxon < ActiveRecord::Migration
  def self.up
    add_column :taxon, :non_ncbi, :integer, :default => 0
  end

  def self.down
    remove_column :taxon, :non_ncbi
  end
end