class CreateBlastRuns < ActiveRecord::Migration
  def self.up
    create_table :blast_runs, :force => true, do |t|
      t.belongs_to :blast_database
      t.belongs_to :taxon_version
      t.text :parameters
      t.string :program
      t.string :version
      t.string :reference, :limit => 500
      t.string :db
    end
  end

  def self.down
    drop_table :blast_runs
  end
end