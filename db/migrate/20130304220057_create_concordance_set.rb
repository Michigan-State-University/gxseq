class CreateConcordanceSet < ActiveRecord::Migration
  def self.up
    create_table :concordance_sets, :force => true do |t|
      t.belongs_to :assembly
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :concordance_sets
  end
end