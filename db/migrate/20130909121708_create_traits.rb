class CreateTraits < ActiveRecord::Migration
  def self.up
    create_table :traits, :force => true do |t|
      t.references :term
      t.references :sample
      t.references :user
      t.string :value
    end
  end

  def self.down
    drop_table :traits
  end
end