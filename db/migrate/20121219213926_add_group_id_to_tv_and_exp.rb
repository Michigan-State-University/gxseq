class AddGroupIdToTvAndExp < ActiveRecord::Migration
  def self.up
    add_column :taxon_versions, :group_id, :integer
    add_column :experiments, :group_id, :integer
    add_index :experiments, [:taxon_version_id, :group_id, :user_id], :name => :experiment_idx1
    add_index :groups_users, [:group_id, :user_id], :name => :groups_users_idx1
  end

  def self.down
    remove_column :taxon_versions, :group_id
    remove_column :experiments, :group_id
  end
end