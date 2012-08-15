class AddSourceToTrack < ActiveRecord::Migration
  def self.up
    add_column :tracks, :source_term_id, :integer
  end

  def self.down
    remove_column :tracks, :source_term_id
  end
end