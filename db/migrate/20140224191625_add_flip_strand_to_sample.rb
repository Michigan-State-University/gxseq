class AddFlipStrandToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :flip_strand, :string
  end

  def self.down
    remove_column :samples, :flip_strand
  end
end