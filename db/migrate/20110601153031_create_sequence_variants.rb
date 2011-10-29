class CreateSequenceVariants < ActiveRecord::Migration
  def self.up
    create_table :sequence_variants, :force => true do |t|
      t.references :experiment
      t.references :bioentry
      t.integer :pos
      t.string :ref
      t.string :alt
      t.integer :qual
      t.float :frequency
      t.string :type
      t.integer :depth
      t.timestamps
    end
    add_index :sequence_variants, [:experiment_id, :pos], :name => :seq_variant_idx
    add_index :sequence_variants, [:experiment_id, :bioentry_id], :name => :seq_variant_idx_1
    add_index :sequence_variants, [:experiment_id, :bioentry_id, :pos], :name => :seq_variant_idx_2
  end

  def self.down
    drop_table :sequence_variants
  end
end