class DeleteBlastReports < ActiveRecord::Migration
  def self.up
    BlastReport.all.each do |r|
      r.destroy
    end
  end

  def self.down
  end
end
