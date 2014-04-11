class ChipSeqsController < ApplicationController
  load_and_authorize_resource
  
  ## custom actions - rjs 
  def initialize_sample
    @chip_seq.initialize_sample
    render :update do |page|
      page.replace_html 'initialize_sample', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def compute_peaks
    render :update do |page|
      peak_count = @chip_seq.compute_peaks
      page.replace_html 'remote_peak_action', "Found #{peak_count} peaks\nRefresh to view them."
    end
  end
  
  ## Standard Rest
  def index
    query = (params[:query] || '').upcase
    @chip_seqs = ChipSeq.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @chip_seqs.map(&:assembly).map(&:species).uniq
  end

  def new
    @chip_seq.assets.build
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def create
    @chip_seq.user = current_user
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    begin
      if @chip_seq.valid?
        @chip_seq.save
        flash[:notice]="Sample created succesfully"
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from Chip Seq\n#{$!}\n#{caller.join("\n")}\n\n"
      flash[:error]="Could not create sample"
      redirect_to :action => :index
    end
  end

  def show
    @bioentry = Biosql::Bioentry.find(params[:bioentry_id] || @chip_seq.bioentries.first.id) rescue nil
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
    if @chip_seq.update_attributes(params[:chip_seq])
      flash[:notice] = 'ChipSeq was successfully updated.'
      redirect_to(@chip_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @chip_seq.destroy
    flash[:warning]="Sample #{@chip_seq.name} has been removed"
    redirect_to :action => :index
  end 
end
