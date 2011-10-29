class CreateTracks < ActiveRecord::Migration
  def self.up
    create_table :tracks, :force => true do |t|
      t.string  :type
      t.belongs_to :bioentry
      t.belongs_to :experiment
      t.timestamps
    end
  end

  def self.down
    drop_table :tracks
  end
end
