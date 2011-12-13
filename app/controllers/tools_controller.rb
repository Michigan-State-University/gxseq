class ToolsController < ApplicationController
  def smooth
    @experiments = Experiment.all(:order => :created_at, :conditions => "type in ('ChipSeq','ChipChip')")
    # TODO implement auth for experiments
    #@experiments.reject!{|e| ! current_user.can_view(e)}
    
    #create a new smoothed dataset from the supplied experiment.
    if(request.post?)
      #check params create the experiment
      begin
        @original=Experiment.find(params[:experiment_id])
        #just to test validity
        @new_experiment = @original.clone({:name => params[:name], :description => params[:description]})
        if(@new_experiment.valid?)
          @original.create_smoothed_experiment( {:name => params[:name], :description => params[:description]}, # pass the exp options again (for use in backgorund job)
            {:window => params[:window].to_i,:type => params[:type],:cutoff => params[:cutoff]}
          )
          flash[:notice] = "Job submitted, smoothing in progress"
          redirect_to :action => :index
        else
          render :action => "smooth"
        end
      rescue
        logger.info "\n\nError Smoothing dataset: #{$!}\n\n"
        flash[:error] = "Could not create new experiment"
        redirect_to :action => "smooth"
      end
    else      
      #render the form
    end
  end
  
  def details
  end
  
  def variant_genes
    @taxon_versions = TaxonVersion.all
    @variants, @variant_genes = [],[]
    if request.xhr?
      if(params[:taxon_version_id])
        @variants = TaxonVersion.find(params[:taxon_version_id]).variants rescue []
      end
      render :partial => 'variant_genes_experiments'
    elsif params[:taxon_version_id]
      t = TaxonVersion.find(params[:taxon_version_id]) rescue nil
      @variants = t.variants rescue []
      if(params[:set_a] && params[:set_b] && t)
        logger.info "\n\nBioentry count: #{t.bioentries.length}\n\n"
        @variant_genes = GeneModel.find_differential_variants(params[:set_a],params[:set_b],)
        @variant_genes = @variant_genes.where{bioentry_id.in(my{t.bioentries})}
        @variant_genes = @variant_genes.includes(:gene,:bioentry)
        @variant_genes = @variant_genes.order(:bioentry_id,:start_pos)
        @variant_genes = @variant_genes.paginate(:page => (params[:page] || 1), :per_page => 25)
      else
        flash.now[:error] = "You must select at least 1 experiment from Set A and Set B"
      end
    else
      t = TaxonVersion.first
      @variants = t.variants rescue []
      params[:taxon_version_id] = t.id rescue nil
    end
  end
  
  # GET /tools
  def index
    #@tools = Tool.all
    @jobs = Delayed::Job.find_by_sql("select id, handler, created_at, locked_at, failed_at, handler, last_error from delayed_jobs")
    # index.html.erb
  end
  
  # DELETE /tools/1
  def destroy
    @job = Delayed::Job.find_by_id(params[:id])
    @job.destroy
    respond_to do |wants|
      wants.html { redirect_to(tools_url) }
    end
  end
  # 
  #  # GET /_tools/1
  #  def show
  #  # show.html.erb
  #  end
  # 
  #  # GET /tools/new
  #  def new
  #    @tool = Tool.new
  #  # new.html.erb
  #  end
  # 
  #  # GET /tools/1/edit
  #  def edit
  #  end
  # 
  #  # POST /tools
  #  def create
  #    @tool = Tool.new(params[:tool])
  # 
  #    respond_to do |wants|
  #      if @tool.save
  #        flash[:notice] = 'Tool was successfully created.'
  #        wants.html { redirect_to(@tool) }
  #      else
  #        wants.html { render :action => "new" }
  #      end
  #    end
  #  end
  # 
  #  # PUT /tools/1
  #  def update
  #    respond_to do |wants|
  #      if @tool.update_attributes(params[:tool])
  #        flash[:notice] = 'Tool was successfully updated.'
  #        wants.html { redirect_to(@tool) }
  #      else
  #        wants.html { render :action => "edit" }
  #      end
  #    end
  #  end
  # 

  # 
  #  private
  #    def find_tool
  #      @tool = Tool.find(params[:id])
  #    end
end
