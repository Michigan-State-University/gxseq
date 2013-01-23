class RnaSeqsController < ApplicationController
  load_and_authorize_resource
  
  ##custom actions - rjs
  def initialize_experiment
    @rna_seq.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @rna_seqs = RnaSeq.accessible_by(current_ability).includes(:taxon_version => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @rna_seqs.map(&:taxon_version).map(&:species).uniq
  end

  def new
    @rna_seq.assets.build
    @taxon_versions = TaxonVersion.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def create
    @rna_seq.user = current_user
    @taxon_versions = TaxonVersion.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    begin
      if @rna_seq.valid?
        @rna_seq.save
        flash[:notice]="Experiment created succesfully"
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from RnaSeq Exp:#{$!}\n\n"
      flash[:error]="Could not create experiment"
      redirect_to :action => :index
    end
  end

  def show
    #TODO: consolidate the entry_id/bioentry_id parameter
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Bioentry.find(entry_id || @rna_seq.bioentries_experiments.first.bioentry_id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @taxon_versions = TaxonVersion.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def update
    @rna_seq.user = current_user
    @taxon_versions = TaxonVersion.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    if @rna_seq.update_attributes(params[:rna_seq])        
      flash[:notice] = 'mRNA-Seq was successfully updated.'
      redirect_to(@rna_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @rna_seq.destroy
    flash[:warning]="Experiment #{@rna_seq.name} has been removed"
    redirect_to :action => :index
  end
end
