class AddUniqueToFeatureCount < ActiveRecord::Migration
  def self.up
    add_column :feature_counts, :unique_count, :integer
  end

  def self.down
    remove_column :feature_counts, :unique_count
  end
end