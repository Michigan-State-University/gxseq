class CreateBlastReports < ActiveRecord::Migration
  def self.up
    create_table :blast_reports, :force => true do |t|
      t.references :seqfeature,  :null => false
      t.references :blast_run, :null => false
      t.text :report
      t.string :hit_acc
      t.string :hit_def
      t.timestamps
    end
  end

  def self.down
    drop_table :blast_reports
  end
end