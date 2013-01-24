class CreateBlastDatabases < ActiveRecord::Migration
  def self.up
    create_table :blast_databases do |t|
      t.string :name
      t.string :abbreviation
      t.string :link_ref
      t.string :description
      t.string :taxon_id
      t.string :data_file_name
      t.string :data_content_type
      t.integer :data_file_size
      t.datetime :data_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :blast_databases
  end
end
