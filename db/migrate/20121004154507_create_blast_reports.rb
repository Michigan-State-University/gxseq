class CreateBlastReports < ActiveRecord::Migration
  def self.up
    create_table :blast_reports, :force => true do |t|
      t.references :seqfeature
      t.references :blast_run
      t.text :report
      t.string :hit_acc
      t.string :hit_def, :limit => 4000
      t.timestamps
    end
  end

  def self.down
    drop_table :blast_reports
  end
end