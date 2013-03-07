class RemoveBioentriesExperiments < ActiveRecord::Migration
  def self.up
    drop_table :bioentries_experiments
  end

  def self.down
    create_table :bioentries_experiments, :force => true do |t|
      t.references :bioentry
      t.references :experiment
      t.string :sequence_name
      t.decimal :abs_max, :scale => 2, :precision => 15
      t.timestamps
    end
  end
end
