class ConvertVariantTrackSampleToGenotype < ActiveRecord::Migration
  def self.up
    rename_column :tracks, :sample, :genotype_sample
  end

  def self.down
    rename_column :tracks, :genotype_sample, :sample
  end
end