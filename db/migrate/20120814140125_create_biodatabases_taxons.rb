class CreateBiodatabasesTaxons < ActiveRecord::Migration
  def self.up
    create_table :biodatabases_taxons, :force => true, :id => false do |t|
      t.belongs_to :biodatabase
      t.belongs_to :taxon
    end
  end

  def self.down
    drop_table :biodatabases_taxons
  end
end