class TransferSerializedBlastReports < ActiveRecord::Migration
  def self.up
    BlastReport.transaction do
      BlastRun.all.each do |blast_run|
        blast_run.blast_reports.select('id,seqfeature_id,report').find_in_batches(:batch_size => 500) do |batch|
          batch.each do |blast_report|
            blast_report.report.iterations.each do |iteration|
              BlastRun.populate_blast_iteration(blast_run.id,iteration,blast_report.seqfeature_id)
            end
          end
        end
      end
    end
    puts "You may want to re-index after this step."
  end

  def self.down
  end
end
