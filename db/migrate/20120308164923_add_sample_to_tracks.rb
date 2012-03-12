class AddSampleToTracks < ActiveRecord::Migration
  def self.up
    add_column :tracks, :sample, :string
  end

  def self.down
    remove_column :tracks, :sample
  end
end