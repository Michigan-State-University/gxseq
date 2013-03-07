class MoveGcFileToTaxonVersion < ActiveRecord::Migration
  def self.up
    # Remove any existing sequence files
    SequenceFile.delete_all
    # Add the new foreign key
    rename_column :sequence_files, :bioentry_id, :taxon_version_id
    remove_column :sequence_files, :version
    add_index :sequence_files, :taxon_version_id
  end

  def self.down
    remove_index :sequence_files, :taxon_version_id
    rename_column :sequence_files, :taxon_version_id, :bioentry_id
    add_column :sequence_files, :version, :integer
  end
end