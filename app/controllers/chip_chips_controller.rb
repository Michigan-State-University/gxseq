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
    unless(params[:query].blank?)
      @species = ChipChip.all(:conditions => ["upper(name) like ?", "%#{params[:query].upcase}%"]).map(&:bioentries).flatten.uniq.collect(&:taxon).uniq.collect(&:species).uniq
    else
      @species = ChipChip.all.map(&:bioentries).flatten.uniq.collect(&:taxon).uniq.collect(&:species).uniq
    end
  end

  def new
    @chip_chip = ChipChip.new()
    @chip_chip.assets.build
    @chip_chip.bioentries_experiments.build
    @bioentries = Bioentry.find(:all, :include => [:source_features => [:qualifiers]], :order => "taxon_id asc, name")
    @species = Bioentry.all_taxon
  end

  def create
    @chip_chip = ChipChip.new(params[:chip_chip])
    @bioentries = Bioentry.find(:all, :order => "name asc")
    begin
      if @chip_chip.valid?
        @chip_chip.save
        if((w=@chip_chip.assets.map(&:warnings)).empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
          @chip_chip.puts "#{w.join("\n")}"
        end
        redirect_to :action => :index #@chip_chip
      else
        @bioentries = Bioentry.find(:all, :include => [:source_features => [:qualifiers]], :order => "taxon_id asc, name")
        @species = Bioentry.all_taxon
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
    @bioentry = Bioentry.find(params[:entry_id] || @chip_chip.bioentries_experiments.first.bioentry_id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @chip_chip = ChipChip.find(params[:id])
    @bioentries = Bioentry.all
    @species = Bioentry.all_taxon
  end

  def update
    @chip_chip = ChipChip.find(params[:id])
    if @chip_chip.update_attributes(params[:chip_chip])        
      if((w=@chip_chip.assets.map(&:warnings).flatten).empty?)
        flash[:notice] = 'Chip Chip was successfully updated.'
      else
        flash[:warning]="#{w.join("<br/>")}"
        @chip_chip.puts "#{w.join("\n")} #{Time.now}"
      end
      redirect_to(@chip_chip)
    else
      @bioentries = Bioentry.find(:all, :order => "name asc")
      @species = Bioentry.all_taxon
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
