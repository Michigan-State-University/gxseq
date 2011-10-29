class CreateTrackConfigurations < ActiveRecord::Migration
  def self.up
    create_table :track_configurations, :force => true do |t|
      t.belongs_to :track_layout
      t.belongs_to :track
      t.belongs_to :user
      t.string :name
      t.string :data
      t.string :edit
      t.string :height
      t.string :showControls
      t.string :showAdd
      t.string :single
      t.string :color_above
      t.string :color_below
      t.timestamps
    end
  end

  def self.down
    drop_table :track_configurations
  end
end
