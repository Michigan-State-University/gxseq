class RenameTaxonVersionToAssembly < ActiveRecord::Migration
  def self.up
    rename_table :taxon_versions, :assemblies
    rename_column :bioentry, :taxon_version_id, :assembly_id
    rename_column :tracks, :taxon_version_id, :assembly_id
    rename_column :track_layouts, :taxon_version_id, :assembly_id
    rename_column :sequence_files, :taxon_version_id, :assembly_id
    rename_column :blast_runs, :taxon_version_id, :assembly_id
    rename_column :experiments, :taxon_version_id, :assembly_id
    
    remove_index :sequence_files, :taxon_version_id
    add_index :sequence_files, :assembly_id
    
    remove_index :experiments, :name => :experiment_idx1
    add_index :experiments, [:assembly_id, :group_id, :user_id], :name => :experiment_idx1
    
  end

  def self.down
    
    rename_column :experiments, :assembly_id, :taxon_version_id
    rename_column :blast_runs, :assembly_id, :taxon_version_id
    rename_column :sequence_files, :assembly_id, :taxon_version_id
    rename_column :track_layouts, :assembly_id, :taxon_version_id
    rename_column :tracks, :assembly_id, :taxon_version_id
    rename_column :bioentry, :assembly_id, :taxon_version_id
    rename_table :assemblies, :taxon_versions
    
    remove_index :experiments, :name => :experiment_idx1 rescue puts 'experiment_idx1 index not found'
    add_index :experiments, [:taxon_version_id, :group_id, :user_id], :name => :experiment_idx1
    
    remove_index :sequence_files, :assembly_id rescue puts 'sequence_files index not found'
    add_index :sequence_files, :taxon_version_id
  end
end