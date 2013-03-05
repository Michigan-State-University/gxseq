class MoveTracksToTaxonVersion < ActiveRecord::Migration
  def self.up
    Track.delete_all
    TrackLayout.delete_all
    # Change track foreign key
    rename_column :tracks, :bioentry_id, :taxon_version_id
    # Change track layout foreign key
    rename_column :track_layouts, :bioentry_id, :taxon_version_id
    Track.create_all
  end

  def self.down
    rename_column :track_layouts, :taxon_version_id, :bioentry_id
    rename_column :tracks, :taxon_version_id, :bioentry_id
  end
end