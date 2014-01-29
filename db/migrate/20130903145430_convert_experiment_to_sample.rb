class ConvertExperimentToSample < ActiveRecord::Migration
  def self.up
    rename_table :experiments, :samples
    rename_column :components, :experiment_id, :sample_id
    rename_column :tracks, :experiment_id, :sample_id
    rename_column :assets, :experiment_id, :sample_id
    rename_column :peaks, :experiment_id, :sample_id
    rename_column :feature_counts, :experiment_id, :sample_id
    
  end

  def self.down
    rename_column :feature_counts, :sample_id, :experiment_id
    rename_column :peaks, :sample_id, :experiment_id
    rename_column :assets, :sample_id, :experiment_id
    rename_column :tracks, :sample_id, :experiment_id
    rename_column :components, :sample_id, :experiment_id
    rename_table :samples, :experiments
  end
end