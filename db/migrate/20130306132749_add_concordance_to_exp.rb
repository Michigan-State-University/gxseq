class AddConcordanceToExp < ActiveRecord::Migration
  def self.up
    add_column :experiments, :concordance_set_id, :integer
  end

  def self.down
    remove_column :experiments, :concordance_set_id
  end
end