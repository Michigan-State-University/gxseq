class ChipSeqsController < ApplicationController
  
  ##custom actions - rjs
  def initialize_experiment
    @chip_seq = ChipSeq.find(params[:id])
    @chip_seq.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def compute_peaks
    render :update do |page|
      @chip_seq = ChipSeq.find(params[:id])
      peak_count = @chip_seq.compute_peaks
      page.replace_html 'remote_peak_action', "Found #{peak_count} peaks\nRefresh to view them."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @species = ChipSeq.includes(:taxon_version).where{upper(name) =~ "%#{query}%"}.collect(&:taxon_version).collect(&:species).uniq
  end

   def new
      @chip_seq = ChipSeq.new()
      @chip_seq.assets.build
      @taxon_versions = TaxonVersion.order('name asc')
   end

   def create
      @chip_seq = ChipSeq.new(params[:chip_seq])
      @taxon_versions = TaxonVersion.order('name asc')
      begin
        if @chip_seq.valid?
          @chip_seq.save
          if((w=@chip_seq.assets.map(&:warnings).flatten).empty?)
            flash[:notice]="Experiment created succesfully"
          else
            flash[:warning]="#{w.join("<br/>")}"
            @chip_seq.puts "#{w.join("\n")}"
          end
          redirect_to :action => :index #@chip_seq
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
      @chip_seq = ChipSeq.find(params[:id])
          @bioentry = Bioentry.find(params[:entry_id] || @chip_seq.bioentries_experiments.first.bioentry_id)
      respond_to do |format|
        format.html {}
        format.xml { render :layout => false }
      end
   end

   def edit
      @chip_seq = ChipSeq.find(params[:id])
      @taxon_versions = TaxonVersion.order('name asc')
   end

   def update
      @chip_seq = ChipSeq.find(params[:id])
      @taxon_versions = TaxonVersion.order('name asc')
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
    @chip_seq = ChipSeq.find(params[:id])
    if (current_user.is_admin? || current_user.owns?(@chip_seq))
      @chip_seq.destroy
      flash[:warning]="Experiment #{@chip_seq.name} has been removed"
      redirect_to :action => :index
    else
      flash[:error]="Not Permitted"
      redirect_to :action => :index
    end
  end 
end
