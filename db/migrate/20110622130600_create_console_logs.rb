class CreateConsoleLogs < ActiveRecord::Migration
  def self.up
    create_table :console_logs, :force => true do |t|
      t.belongs_to :loggable, :polymorphic => true
      t.text :console
      t.timestamps
    end
  end

  def self.down
    drop_table :console_logs
  end
end