class ToolsController < ApplicationController
  def smooth
    @experiments = Experiment.all(:order => :created_at, :conditions => "type in ('ChipChip','ChipSeq','RnaSeq')")    
    #create a new smoothed dataset from the supplied experiment.
    if(request.post?)
      begin
        @original=Experiment.find(params[:experiment_id])
        # just to test validity
        @new_experiment = @original.clone({:name => params[:name], :description => params[:description]})
        # needs an asset to be valid...
        @new_experiment.assets.build({:type => "BigWig",:data => Tempfile.new('test.bigwig')})
        if(@new_experiment.valid?)
          @original.delay.create_smoothed_experiment( {:name => params[:name], :description => params[:description]}, # pass the exp options again (for use in backgorund job)
            {:window => params[:window].to_i,:type => params[:type],:cutoff => params[:cutoff]}
          )
          flash[:notice] = "The Smoothing Job has been submitted. When it is complete #{params[:name]} will be listed with the other #{@original.class} experiments"
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
  
  def expression_viewer
    # grab the taxon versions that have rna_seq experiments
    @taxon_versions = TaxonVersion.order(:name).includes(:experiments).where("experiments.type = 'RnaSeq'")
    begin
      @taxon_version = TaxonVersion.find(params[:taxon_version_id]) if params[:taxon_version_id]
      # limiting to experiments with counts is slow on mysql
      #@experiment_options = @taxon_version.rna_seqs.includes(:feature_counts).where("feature_counts.count is not null") if @taxon_version
      @experiment_options = @taxon_version.rna_seqs if @taxon_version
      
    rescue
    end
  end
  
  def advanced_expression_viewer
  
  end
  
  def expression_results
    begin
      @search = Gene.search do
        keywords params[:keywords], :fields => [:qualifier_values], :highlight => true
        with(:locus_tag, params[:locus_tag]) unless params[:locus_tag].blank?
        paginate(:page => params[:page])
      end
    rescue
      @search = []
    end
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
      if(params[:set_a] && t)
        @variant_genes = GeneModel.find_differential_variants(params[:set_a],params[:set_b]||[])
        @variant_genes = @variant_genes.where{bioentry_id.in(my{t.bioentries})}
        @variant_genes = @variant_genes.includes(:gene,:bioentry)
        @variant_genes = @variant_genes.order(:bioentry_id,:start_pos)        
      else
        flash.now[:error] = "You must select at least 1 experiment from Set A and Set B"
      end
    else
      t = TaxonVersion.first
      @variants = t.variants rescue []
      params[:taxon_version_id] = t.id rescue nil
    end
    respond_to do |format|
      format.csv {
        csv_out = CSV.generate do |csv|
          csv <<  ["Locus Tag","Gene","Start","End","Strand","Sequence"]
          @variant_genes.each do |gm|
            csv << [ gm.display_name, gm.gene_name, gm.start_pos, gm.end_pos, (gm.strand == 1 ? 'Forward' : 'Reverse'), gm.bioentry.short_name ]
          end
        end
        send_data csv_out, 
        :type => 'text/csv; charset=iso-8859-1; header=present', 
        :disposition => "attachment; filename=variant_genes_#{Time.now.to_i}.csv"
      }
      format.html {
        unless @variant_genes.empty?
          @variant_genes = @variant_genes.paginate(:page => (params[:page] || 1), :per_page => 25)
        end
      }
      if(@variant_genes.empty?)
        flash.now[:warning]= "No genes found matching the given criteria. Please expand your search."
      end
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
