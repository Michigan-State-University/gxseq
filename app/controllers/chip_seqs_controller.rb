class ChipSeqsController < ApplicationController
  load_and_authorize_resource
  
  ## custom actions - rjs 
  def initialize_experiment
    @chip_seq.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
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
        if((w=@chip_seq.assets.map(&:warnings).flatten).empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
          @chip_seq.puts "#{w.join("\n")}"
        end
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from Chip Seq\n#{$!}\n#{caller.join("\n")}\n\n"
      flash[:error]="Could not create experiment"
      redirect_to :action => :index
    end
  end

  def show
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Biosql::Bioentry.find(entry_id || @chip_seq.assembly.bioentries.first.id)
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
      if((w=@chip_seq.assets.map(&:warnings).flatten).empty?)
        flash[:notice] = 'ChipSeq was successfully updated.'
      else
        flash[:warning]="#{w.join("<br/>")}"
        @chip_seq.puts "#{w.join("\n")} #{Time.now}"
      end
      redirect_to(@chip_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @chip_seq.destroy
    flash[:warning]="Experiment #{@chip_seq.name} has been removed"
    redirect_to :action => :index
  end 
end
