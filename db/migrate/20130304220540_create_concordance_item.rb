class CreateConcordanceItem < ActiveRecord::Migration
  def self.up
    create_table :concordance_items, :force => true do |t|
      t.belongs_to  :concordance_set
      t.belongs_to  :bioentry
      t.string      :reference_name
      t.timestamps  
    end
  end

  def self.down
    drop_table :concordance_items
  end
end