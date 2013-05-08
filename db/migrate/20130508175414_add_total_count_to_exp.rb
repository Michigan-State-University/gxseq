class AddTotalCountToExp < ActiveRecord::Migration
  def self.up
    add_column :experiments, :total_count, :integer
  end

  def self.down
    remove_column :experiments, :total_count
  end
end