class ReSeqsController < ApplicationController
  load_and_authorize_resource
  
  ##custom actions - rjs
  def initialize_experiment
    @re_seq.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @re_seqs = ReSeq.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @re_seqs.map(&:assembly).map(&:species).uniq
  end

  def new
    @re_seq.assets.build
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def create
    @re_seq.user = current_user
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    begin
      if @re_seq.valid?
        @re_seq.save
        flash[:notice]="Experiment created succesfully"
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from ReSeq Exp:#{$!}\n\n"
      flash[:error]="Could not create experiment"
      redirect_to :action => :index
    end
  end

  def show
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Biosql::Bioentry.find(entry_id || @re_seq.assembly.bioentries.first.id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def update
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    if @re_seq.update_attributes(params[:re_seq])        
      flash[:notice] = 'Re-Sequencing experiment was successfully updated.'
      redirect_to(@re_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @re_seq.destroy
    flash[:warning]="Experiment #{@re_seq.name} has been removed"
    redirect_to :action => :index
  end
end
