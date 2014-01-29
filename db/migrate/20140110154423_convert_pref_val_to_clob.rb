class ConvertPrefValToClob < ActiveRecord::Migration
  def self.up
    drop_table :preferences
    create_table :preferences do |t|
      t.string :name, :null => false
      t.references :owner, :polymorphic => true, :null => false
      t.references :group, :polymorphic => true
      t.text :value
      t.timestamps
    end
    add_index :preferences, [:owner_id, :owner_type, :name, :group_id, :group_type], :unique => true, :name => 'owner_name_group_pref_idx'
  end
  
  def self.down
  end
end
