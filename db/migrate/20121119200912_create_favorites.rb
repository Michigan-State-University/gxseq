class CreateFavorites < ActiveRecord::Migration
  def self.up
    create_table :favorites do |t|
      t.belongs_to :user
      t.string :type
      t.integer :favorite_item_id
      t.timestamps
    end     
  end

  def self.down
    drop_table :favorites
  end
end
