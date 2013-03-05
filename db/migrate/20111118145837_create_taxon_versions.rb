class CreateTaxonVersions < ActiveRecord::Migration
  def self.up
    create_table :taxon_versions, :force => true do |t|
      t.belongs_to :taxon
      t.belongs_to :species
      t.string :name
      t.string :version
      t.timestamps
    end
  end

  def self.down
    drop_table :taxon_versions
  end
end