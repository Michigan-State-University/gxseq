class CreateComponents < ActiveRecord::Migration
  def self.up
      create_table :components, :force => true do |t|
        t.string :type
        t.belongs_to :experiment
        t.belongs_to :synthetic_experiment
        t.timestamps
      end
  end

  def self.down
      drop_table :components
  end
end
