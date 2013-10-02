class AddBlastIndexes < ActiveRecord::Migration
  def self.up
    add_index :blast_iterations, :seqfeature_id
    add_index :hits, :blast_iteration_id
    add_index :hsps, :hit_id
  end

  def self.down
    remove_index :hsps, :hit_id
    remove_index :hits, :blast_iteration_id
    remove_index :blast_iterations, :seqfeature_id
  end
end