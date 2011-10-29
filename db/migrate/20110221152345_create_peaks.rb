class CreatePeaks < ActiveRecord::Migration
  def self.up
    create_table :peaks, :force => true do |t|
      t.belongs_to :experiment
      t.belongs_to :bioentry
      t.integer :start_pos
      t.integer :end_pos
      t.float :val
      t.integer :pos
      t.timestamps
    end
  end

  def self.down
    drop_table :peaks
  end
end