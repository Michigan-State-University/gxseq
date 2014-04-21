class RemoveSampleSequenceName < ActiveRecord::Migration
  def self.up
    remove_column :samples, :sequence_name
  end

  def self.down
    add_column :samples, :sequence_name, :string
  end
end
