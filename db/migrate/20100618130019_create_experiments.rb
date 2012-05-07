class CreateExperiments < ActiveRecord::Migration
  def self.up
      create_table :experiments, :force => true do |t|
        t.belongs_to :bioentry
        t.belongs_to :taxon_version
        t.belongs_to :user
        t.string  :name
        t.string :type
        t.string :description, :limit => 500
        t.string :file_name
        t.string :a_op
        t.string :b_op
        t.string :mid_op
        t.string :sequence_name
        t.string :state
        t.string :show_negative
        t.timestamps
      end
  end

  def self.down
      drop_table :experiments
  end
end
