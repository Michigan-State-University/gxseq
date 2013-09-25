class BlastRunsController < ApplicationController
  def show
    @blast_run = BlastRun.find(params[:id])
    @blast_report = BlastIteration.find_by_id(params[:blast_report_id]) if params[:blast_report_id]
    @blast_report ||= @blast_run.blast_iterations.first
    @blast_reports = @blast_run.blast_iterations.paginate(:page =>  (params[:page] || 1), :per_page => 15)
  end
end