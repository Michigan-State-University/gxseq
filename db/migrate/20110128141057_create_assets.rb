class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets, :force => true do |t|
      t.string      :type
      t.belongs_to  :experiment
      t.string      :data_file_name
      t.string      :data_content_type
      t.string      :state, :default => 'pending'
      t.integer     :data_file_size
      t.datetime    :data_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :assets
  end
end