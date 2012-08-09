class AddCompletedAtToDelayedJob < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :completed_at, :datetime
  end

  def self.down
    remove_column :delayed_jobs, :completed_at
  end
end
