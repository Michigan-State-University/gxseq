class ChipChipsController < ApplicationController
  load_and_authorize_resource
  
  ##custom actions - rjs
  def initialize_experiment
    @chip_chip.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def compute_peaks
    render :update do |page|
      peak_count = @chip_chip.compute_peaks
      page.replace_html 'compute_peaks', "Found #{peak_count} peaks\nRefresh to view them."
    end
  end

  def index
    query = (params[:query] || '').upcase
    @chip_chips = ChipChip.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @chip_chips.map(&:assembly).map(&:species).uniq
  end

  def new
    @chip_chip.assets.build
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def create
    @chip_chip.user = current_user
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    begin
      if @chip_chip.valid?
        @chip_chip.save
        if((w=@chip_chip.assets.map(&:warnings).flatten).empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
          @chip_chip.puts "#{w.join("\n")}"
        end
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from Chip Chip#{$!}\n\n"
      flash[:error]="Could not create experiment"
      redirect_to :action => :index
    end
  end

  def show
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Bio::Bioentry.find(entry_id || @chip_chip.assembly.bioentries.first.id)
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
    if @chip_chip.update_attributes(params[:chip_chip])        
      if((w=@chip_chip.assets.map(&:warnings).flatten).empty?)
        flash[:notice] = 'Chip Chip was successfully updated.'
      else
        flash[:warning]="#{w.join("<br/>")}"
        @chip_chip.puts "#{w.join("\n")} #{Time.now}"
      end
      redirect_to(@chip_chip)
    else
      render :action => "edit"
    end
  end

  def destroy
    @chip_chip.destroy
    flash[:warning]="Experiment #{@chip_chip.name} has been removed"
    redirect_to :action => :index
  end
end
