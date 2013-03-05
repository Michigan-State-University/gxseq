class MoveGcFileToTaxonVersion < ActiveRecord::Migration
  def self.up
    # Remove any existing sequence files
    SequenceFile.delete_all
    # Add the new foreign key
    add_column :sequence_files, :taxon_version_id, :integer
    # Remove the old foreign keys
    remove_column :sequence_files, :bioentry_id
    remove_column :sequence_files, :version
    add_index :sequence_files, :taxon_version_id
  end

  def self.down
    remove_index :sequence_files, :taxon_version_id
    remove_column :sequence_files, :taxon_version_id
    add_column :sequence_files, :bioentry_id
    add_column :sequence_files, :version
  end
end