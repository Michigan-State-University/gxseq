class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.string   :item_type, :null => false
      t.string   :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at
      # Metadata columns
      t.integer :parent_id # polymorphic parent
      t.string  :parent_type
    end
    add_index :versions, [:item_type, :item_id]
    add_index :versions, [:parent_type, :parent_id, :item_type]
  end

  def self.down
    drop_table :versions
  end
end
