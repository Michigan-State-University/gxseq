class AddGroupIdToBlastDatabase < ActiveRecord::Migration
  def self.up
    add_column :blast_databases, :group_id, :integer
  end

  def self.down
    remove_column :blast_databases, :group_id
  end
end