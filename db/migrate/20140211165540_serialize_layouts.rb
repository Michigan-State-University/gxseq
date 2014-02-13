class SerializeLayouts < ActiveRecord::Migration
  def self.up
    remove_column :track_configurations, :name
    remove_column :track_configurations, :data
    remove_column :track_configurations, :edit
    remove_column :track_configurations, :height
    remove_column :track_configurations, :showControls
    remove_column :track_configurations, :showAdd
    remove_column :track_configurations, :single
    remove_column :track_configurations, :color_above
    remove_column :track_configurations, :color_below
    add_column :track_configurations, :track_config, :text
  end

  def self.down
    remove_column :track_configurations, :track_config
    add_column :track_configurations, :name, :string
    add_column :track_configurations, :data, :string
    add_column :track_configurations, :edit, :string
    add_column :track_configurations, :height, :string
    add_column :track_configurations, :showControls, :string
    add_column :track_configurations, :showAdd, :string
    add_column :track_configurations, :single, :string
    add_column :track_configurations, :color_above, :string
    add_column :track_configurations, :color_below, :string
  end
end