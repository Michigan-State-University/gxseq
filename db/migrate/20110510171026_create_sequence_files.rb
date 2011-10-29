class CreateSequenceFiles < ActiveRecord::Migration
  def self.up
    create_table :sequence_files, :force => true do |t|
      t.string      :type
      t.integer     :bioentry_id
      t.integer     :version
      t.string      :data_file_name
      t.string      :data_content_type
      t.integer     :data_file_size
      t.datetime    :data_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :sequence_files
  end
end
