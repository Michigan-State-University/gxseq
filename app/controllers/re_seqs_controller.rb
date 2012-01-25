class ReSeqsController < ApplicationController

  ##custom actions - rjs
  def initialize_experiment
    @re_seq = ReSeq.find(params[:id])
    @re_seq.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @species = ReSeq.includes(:taxon_version).where{upper(name) =~ "%#{query}%"}.collect(&:taxon_version).collect(&:species).uniq
  end

  def new
    @re_seq = ReSeq.new()
    @re_seq.assets.build
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def create
    @re_seq = ReSeq.new(params[:re_seq])
    @taxon_versions = TaxonVersion.order('name asc')
    begin
      if @re_seq.valid?
        @re_seq.save
        if((w=@re_seq.assets.map(&:warnings).flatten).empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
          @re_seq.puts "#{w.join("\n")}"
        end
        redirect_to :action => :index #@re_seq
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
    @re_seq = ReSeq.find(params[:id])
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Bioentry.find(entry_id || @re_seq.bioentries_experiments.first.bioentry_id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @re_seq = ReSeq.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def update
    @re_seq = ReSeq.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
    if @re_seq.update_attributes(params[:re_seq])        
      if((w=@re_seq.assets.map(&:warnings).flatten).empty?)
        flash[:notice] = 'Re-Sequencing experiment was successfully updated.'
      else
        flash[:warning]="#{w.join("<br/>")}"
        @re_seq.puts "#{w.join("\n")} #{Time.now}"
      end
      redirect_to(@re_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @re_seq = ReSeq.find(params[:id])
    if (current_user.is_admin? || current_user.owns?(@re_seq))
      @re_seq.destroy
      flash[:warning]="Experiment #{@re_seq.name} has been removed"
      redirect_to :action => :index
    else
      flash[:error]="Not Permitted"
      redirect_to :action => :index
    end
  end
end
