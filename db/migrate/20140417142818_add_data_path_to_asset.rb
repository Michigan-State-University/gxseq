class AddDataPathToAsset < ActiveRecord::Migration
  def self.up
    add_column :assets, :local_path, :string
  end

  def self.down
    remove_column :assets, :local_path
  end
end