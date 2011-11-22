class ChipChipsController < ApplicationController

  ##custom actions - rjs
  def initialize_experiment
    @chip_chip = ChipChip.find(params[:id])
    @chip_chip.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def compute_peaks
    render :update do |page|
      @chip_chip = ChipChip.find(params[:id])
      peak_count = @chip_chip.compute_peaks
      page.replace_html 'compute_peaks', "Found #{peak_count} peaks\nRefresh to view them."
    end
  end

  def index
    query = (params[:query] || '').upcase
    @species = ChipChip.includes(:taxon_version).where{upper(name) =~ "%#{query}%"}.collect(&:taxon_version).collect(&:species).uniq
  end

  def new
    @chip_chip = ChipChip.new()
    @chip_chip.assets.build
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def create
    @chip_chip = ChipChip.new(params[:chip_chip])
    @taxon_versions = TaxonVersion.order('name asc')
    begin
      if @chip_chip.valid?
        @chip_chip.save
        if((w=@chip_chip.assets.map(&:warnings).flatten).empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
          @chip_chip.puts "#{w.join("\n")}"
        end
        redirect_to :action => :index #@chip_chip
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
    @chip_chip = ChipChip.find(params[:id])
    @bioentry = Bioentry.find(params[:bioentry_id] || @chip_chip.bioentries_experiments.first.bioentry_id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @chip_chip = ChipChip.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def update
    @chip_chip = ChipChip.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
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
    @chip_chip = ChipChip.find(params[:id])
    if (current_user.is_admin?)
      @chip_chip.destroy
      flash[:warning]="Experiment #{@chip_chip.name} has been removed"
      redirect_to :action => :index
    else
      flash[:error]="Not Permitted"
      redirect_to :action => :index
    end
  end
end
