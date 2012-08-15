class CreateFeatureCounts < ActiveRecord::Migration
  def self.up
    create_table :feature_counts, :force => true do |t|
      t.belongs_to :seqfeature
      t.belongs_to :experiment
      t.integer :count
      t.decimal :normalized_count, :precision => 10, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :feature_counts
  end
end