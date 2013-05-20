class CreateTrackLayouts < ActiveRecord::Migration
  def self.up
    create_table :track_layouts, :force => true do |t|
      t.belongs_to :bioentry
      t.belongs_to :user
      t.string :name
      t.string :position
      t.string :bases
      t.string :pixels
      t.string :active_tracks
      t.timestamps
    end
  end

  def self.down
    drop_table :track_layouts
  end
end
