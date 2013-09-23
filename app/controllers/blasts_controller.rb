class BlastsController < ApplicationController
  before_filter :setup_defaults
  def index
  end
  
  def new
    params[:blast]||={}
    params[:blast][:program]='blastx'
    params[:blast][:evalue]='0.01'
    params[:blast][:matrix]='BLOSUM62'
  end
  
  def create
    blast_db = BlastDatabase.find(params[:blast][:blast_database_id])
    params[:blast][:filepath]=blast_db.filepath
    local_run = BlastRun.local_blast(params[:blast])
    begin
      if(local_run && local_run.reports && local_run.reports.size > 0 && local_run.reports.collect{|report| report.hits.length}.sum > 0)
        BlastRun.transaction do
          blast_run = BlastRun.create(
            :blast_database => blast_db,
            :parameters => local_run.parameters,
            :program => local_run.program,
            :version => local_run.version,
            :reference => local_run.reference,
            :db => local_run.db,
            :user => current_user,
          )
          local_run.reports.each do |report|
            blast_run.populate_blast_iteration(report)
          end
          redirect_to blast_run
        end
      else
        flash.now[:warning]="No blast hits were found"
        render :new
      end
    rescue => e
      server_error(e,'User blast Error')
      flash.now[:error]="Oops, there was an error with that blast."
      render :new
    end
  end
  
  private
  def setup_defaults
    @blast_databases = BlastDatabase.accessible_by(current_ability).order(:description)
    @evalues = %w(100 10 5 0.1 0.01 1e-5 1e-10 1e-50)
    @matrices = %w(PAM30 PAM70 BLOSUM45 BLOSUM62 BLOSUM80)
    @hits = %w(10 25 50 100)
  end
end