class ConvertSyntheticToCombo < ActiveRecord::Migration
  def self.up
    Sample.connection.execute("update samples set type='Combo' where type='Synthetic'")
    Sample.connection.execute("update tracks set type='ComboTrack' where type='RatioTrack'")
    rename_column :components, :synthetic_sample_id, :combo_sample_id
  end

  def self.down
    rename_column :components, :combo_sample_id, :synthetic_sample_id
  end
end