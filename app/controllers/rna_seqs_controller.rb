class RnaSeqsController < ApplicationController
  load_and_authorize_resource
  
  ##custom actions - rjs
  def initialize_sample
    @rna_seq.initialize_sample
    render :update do |page|
      page.replace_html 'initialize_sample', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @rna_seqs = RnaSeq.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @rna_seqs.map(&:assembly).map(&:species).uniq
  end

  def new
    @rna_seq.assets.build
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def create
    @rna_seq.user = current_user
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    begin
      if @rna_seq.valid?
        @rna_seq.save
        flash[:notice]="Sample created succesfully"
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from RnaSeq Exp:#{$!}\n\n"
      flash[:error]="Could not create sample"
      redirect_to :action => :index
    end
  end

  def show
    #TODO: consolidate the entry_id/bioentry_id parameter
    entry_id = params[:entry_id] || params[:bioentry_id]
    @bioentry = Biosql::Bioentry.find(entry_id || @rna_seq.assembly.bioentries.first.id) rescue nil
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def update
    @rna_seq.user = current_user
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    if @rna_seq.update_attributes(params[:rna_seq])        
      flash[:notice] = 'mRNA-Seq was successfully updated.'
      redirect_to(@rna_seq)
    else
      render :action => "edit"
    end
  end

  def destroy
    @rna_seq.destroy
    flash[:warning]="Sample #{@rna_seq.name} has been removed"
    redirect_to :action => :index
  end
end
