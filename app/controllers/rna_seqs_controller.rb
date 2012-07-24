class RnaSeqsController < ApplicationController

  ##custom actions - rjs
  def initialize_experiment
    @rna_seq = RnaSeq.find(params[:id])
    @rna_seq.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @species = RnaSeq.includes(:taxon_version).where{upper(name) =~ "%#{query}%"}.collect(&:taxon_version).collect(&:species).uniq
  end

  def new
    @rna_seq = RnaSeq.new()
    @rna_seq.assets.build
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def create
    @rna_seq = RnaSeq.new(params[:rna_seq])
    @rna_seq.user = current_user
    @taxon_versions = TaxonVersion.order('name asc')
    begin
      if @rna_seq.valid?
        @rna_seq.save
        if((w=@rna_seq.assets.map(&:warnings).flatten).empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
          @rna_seq.puts "#{w.join("\n")}"
        end
        redirect_to :action => :index #@rna_seq
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
    @rna_seq = RnaSeq.find(params[:id])
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Bioentry.find(entry_id || @rna_seq.bioentries_experiments.first.bioentry_id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @rna_seq = RnaSeq.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def update
    @rna_seq = RnaSeq.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
    if @rna_seq.update_attributes(params[:rna_seq])        
      if((w=@rna_seq.assets.map(&:warnings).flatten).empty?)
        flash[:notice] = 'mRNA-Seq was successfully updated.'
      else
        flash[:warning]="#{w.join("<br/>")}"
        @rna_seq.puts "#{w.join("\n")} #{Time.now}"
      end
      redirect_to(@rna_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @rna_seq = RnaSeq.find(params[:id])
    if (current_user.is_admin? || current_user.owns?(@rna_seq))
      @rna_seq.destroy
      flash[:warning]="Experiment #{@rna_seq.name} has been removed"
      redirect_to :action => :index
    else
      flash[:error]="Not Permitted"
      redirect_to :action => :index
    end
  end
end
