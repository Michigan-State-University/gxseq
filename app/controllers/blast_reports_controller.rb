class BlastReportsController < ApplicationController
  before_filter :find_blast_report, :only => [:show, :alignment, :edit]
  
  def show
  end
  
  def alignment
    @hit = @report.hits.find{|hit| hit.accession == params[:hit_accession]}
    respond_to do |format|
      format.html {render :partial => 'alignment', :locals => {:hit => @hit, :report => @report}}
      format.js {}
    end
  end
  
  def find_blast_report
    @blast_report = BlastReport.find(params[:id])
    @blast_run = @blast_report.blast_run
    @report = @blast_report.report
  end
end
