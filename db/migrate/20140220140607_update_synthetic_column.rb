class UpdateSyntheticColumn < ActiveRecord::Migration
  def self.up
    rename_column :components, :synthetic_experiment_id, :synthetic_sample_id
  end

  def self.down
    rename_column :components, :synthetic_sample_id, :synthetic_experiment_id
  end
end