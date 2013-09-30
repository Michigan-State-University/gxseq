class BlastReportsController < ApplicationController
  before_filter :find_blast_report, :only => [:show, :alignment, :edit]
  
  def show
  end
  
  def alignment
    @hit = @blast_report.hits.find(params[:hit_id])
    respond_to do |format|
      format.html {render :partial => 'alignment', :locals => {:hit => @hit, :report => @blast_report}}
      format.js {}
    end
  end
  
  def find_blast_report
    @blast_report = BlastIteration.find(params[:id])
    @blast_run = @blast_report.blast_run
  end
end
