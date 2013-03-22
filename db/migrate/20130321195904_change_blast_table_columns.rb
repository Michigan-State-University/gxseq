class ChangeBlastTableColumns < ActiveRecord::Migration
  def self.up
    add_column :blast_databases, :filepath, :string
    remove_column :blast_databases, :abbreviation
    add_column :blast_runs, :user_id, :integer
  end

  def self.down
    remove_column :blast_databases, :filepath
    add_column :blast_databases, :abbreviation, :string
    remove_column :blast_runs, :user_id
  end
end