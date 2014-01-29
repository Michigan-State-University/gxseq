class RemoveUniqueRankIndex < ActiveRecord::Migration
  def self.up
    remove_index(:seqfeature, :name => :seqfeature_idx)
    add_index(:seqfeature, [:bioentry_id, :type_term_id], :name => :seqfeature_idx)
  end

  def self.down
    remove_index(:seqfeature, :name => :seqfeature_idx)
    add_index(:seqfeature, [:bioentry_id, :type_term_id, :source_term_id, :rank], :unique => true, :name => :seqfeature_idx)
  end
end
