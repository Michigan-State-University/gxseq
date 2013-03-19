class CreateFeatureCounts < ActiveRecord::Migration
  def self.up
    create_table :feature_counts, :force => true do |t|
      t.belongs_to :seqfeature
      t.belongs_to :experiment
      t.integer :count
      t.decimal :normalized_count, :precision => 10, :scale => 2
      t.timestamps
    end
    add_index :feature_counts, :seqfeature_id, :name => :idx_feature
    add_index :feature_counts, [:experiment_id,:seqfeature_id], :name => :idx_exp_and_feature
    add_index :seqfeature, [:type_term_id,:seqfeature_id], :name => :idx_type_term
  end

  def self.down
    remove_index :seqfeature, :name => :idx_type_term
    drop_table :feature_counts
  end
end