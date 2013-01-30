class GenesController < ApplicationController
  #autocomplete :taxon_version, :id
  autocomplete :bioentry, :id, :full => true
  authorize_resource :class => "GeneModel"
  skip_authorize_resource :only => [:autocomplete_bioentry_id]
  
  before_filter :get_gene_data, :only => [:edit, :update]
  before_filter :new_gene_data, :only => [:new]
  #TODO: Refactor controller. Split into genes_controller gene_models_controller. They are mixed right now...
  def index
    # Defaults
    params[:page]||=1
    params[:c]||='taxon_version_name_with_version'
    order_d = (params[:d]=='down' ? 'desc' : 'asc')
    @presence_items = presence_items = ['gene_name','function','product']
    # Filter setup
    @taxon_versions = TaxonVersion.accessible_by(current_ability).includes(:taxon => :scientific_name).order('taxon_name.name')
    # Find minimum set of id ranges accessible by current user. Set to -1 if no items are found. This will force empty search results
    authorized_id_set = GeneModel.accessible_by(current_ability).select_ids.to_ranges
    authorized_id_set=[-1] if authorized_id_set.empty?
    # Begin block
    @search = GeneModel.search do
      # Auth      
      any_of do |any_s|
        authorized_id_set.each do |id_range|
          any_s.with :id, id_range
        end
      end
      # Text Keywords
      if params[:keywords]
        keywords params[:keywords], :highlight => true
      end
      # Presence Filters
      presence_items.each do |presence_item|
        case params[(presence_item+'_present').to_sym]
        when 't'
          all_of do
            without presence_item.to_sym, nil
          end
        when 'f'
          all_of do
            with presence_item.to_sym, nil
          end
        end
      end
      # Filters
      with :taxon_version_id, params[:taxon_version_id] unless params[:taxon_version_id].blank?
      with :strand, params[:strand] unless params[:strand].blank?
      unless params[:start_pos].blank?
        any_of do
          with(:start_pos).greater_than(params[:start_pos])
          with(:end_pos).greater_than(params[:start_pos])
        end
      end
      unless params[:end_pos].blank?
        any_of do
          with(:start_pos).less_than(params[:end_pos])
          with(:end_pos).less_than(params[:end_pos])
        end
      end
      # Sort
      order_by params[:c].to_sym, order_d
      # Paging 
      paginate(:page => params[:page], :per_page => 50)
      facet :strand
    end
  end
  
  def new
    respond_to do |format|
      format.html{}
    end
  end
  
  def create
    authorize! :create, Gene.new
    begin
      @taxons = Bioentry.all_taxon
      @taxon_versions = TaxonVersion.accessible_by(current_ability).order(:name)
      @gene = Gene.new(params[:gene])
      
      @bioentry = @gene.bioentry
      @taxon_version = @gene.bioentry.taxon_version
      @bioentries = @taxon_version.bioentries
      @annotation_terms = Term.annotation_tags.order(:name).reject{|t|t.name=='locus_tag'}
      seq_src_ont_id = Term.seq_src_ont_id
      @seq_src_term_id = Term.default_source_term.id
      if(@gene.valid?)
        Gene.transaction do
          @gene.save
          redirect_to [:edit,@gene], :notice => "Gene Created Successfully"
        end
      else
        logger.info "\n\n#{@gene.errors.inspect}\n\n"
        flash.now[:warning]="Oops, something wasn't right. Check below..."
        render :new
      end
    rescue
       logger.error("#{$!} #{caller.join("\n")}")
       flash.now[:error]="Error creating Gene"
       render :new
     end
  end
  
  def show
    # TODO: Dry up the seqfeature/gene show methods. Duplicate code
    @format = params[:fmt] || 'standard'
    begin
    case @format
    when 'variants'
      @gene = Gene.find(params[:id])
      @variant_window = [(params[:v_win].to_i || 0),1000].min
      @variant_format = params[:v_fmt] || 'fasta'
    when 'standard'
      # test the id parameter for non numeric characters
      if(params[:id]=~/^\d+$/)
        @gene = Gene.find(params[:id], :include => [:locations,[:bioentry => [:taxon_version]],[:gene_models => [:cds => [:locations, [:qualifiers => :term]],:mrna => [:locations, [:qualifiers => :term]]]],[:qualifiers => :term]])
      else
        @gene = Gene.with_locus_tag(params[:id]).first
      end
      setup_graphics_data
      #check for other genes with the same locus_tag
      @genes = Gene.with_locus_tag( @gene.locus_tag.value)
    when 'genbank'
      @gene = Gene.find(params[:id], :include => [:locations,[:bioentry => [:taxon_version]],[:gene_models => [:cds => [:locations, [:qualifiers => :term]],:mrna => [:locations, [:qualifiers => :term]]]],[:qualifiers => :term]])
      #Note: Find related features (by locus tag until we have a parent<->child relationship)
      @features = @gene.find_related_by_locus_tag
    when 'history'
      @gene = Gene.find(params[:id])
      @changelogs = Version.order('id desc').where(:parent_id => @gene.id).where(:parent_type => 'Gene')
    when 'expression'
      @gene = Gene.find(params[:id])
      @feature_counts = @seqfeature.feature_counts.accessible_by(current_ability)
      @graph_data = FeatureCount.create_graph_data(@feature_counts)
    when 'blast'
      @blast_reports = @gene.blast_reports
      params[:blast_report_id]||=@blast_reports.first.id
      @blast_report = BlastReport.find(params[:blast_report_id])
      @blast_run = @blast_report.blast_run
    end
    rescue => e
      logger.info "\n\n#{e.backtrace}\n\n"
      @gene = nil
    end
    authorize! :read, @gene
  end
  
  def edit
    @format = 'edit'
    authorize! :update, @gene
  end
  
  def update
    authorize! :update, @gene
    begin
      Gene.transaction do
        if(@gene.update_attributes(params[:gene]))
          redirect_to [:edit,@gene], :notice => "Gene Updated successfully"
        else
          flash.now[:warning]="Oops, something wasn't right. Check below..."
          render :edit
        end
      end
    rescue
      if(@gene)
        logger.error("#{$!} #{caller.join("\n")}")
        flash[:error]="Error updating gene"
        redirect_to [:edit,@gene]
      else
        redirect_to :action => :index
      end
    end
  end
  
  private
  
  def new_gene_data
    @taxon_version = @bioentry = nil
    @taxon_versions = TaxonVersion.includes(:taxon => :scientific_name).order('taxon_name.name').accessible_by(current_ability)
    # TODO: refactor this! Ontology doesn't belong here... Should prabably be selected...
    @seq_src_term_id = Term.default_source_term.id
    begin
      params[:taxon_version_id]||=params[:genes][:taxon_version_id] rescue nil
      params[:bioentry_id]||=params[:genes][:bioentry_id] rescue nil
      @gene = Gene.new
    if(params[:taxon_version_id] && @taxon_version = TaxonVersion.accessible_by(current_ability).find(params[:taxon_version_id]))
      @bioentries = @taxon_version.bioentries
      params[:bioentry_id]=@bioentries.first.id if @bioentries.count ==1
      if(params[:bioentry_id] && @bioentry = Bioentry.accessible_by(current_ability).find(params[:bioentry_id]))
        @gene = Gene.new(:bioentry_id => @bioentry.id)
        # add the first blank gene model.
        @gene.gene_models.build
        # Add the locus_tag qualifier. This is required for all genes
        q = @gene.qualifiers.build
        q.term = Term.find_by_name('locus_tag')
        q.term_id = q.term.id
        # Add the blank location
        @gene.locations.build
        # get the annotation terms
        @annotation_terms = Term.annotation_tags.order(:name).reject{|t|t.name=='locus_tag'}
      end
    else
      @bioentries = []
    end
    rescue
    end
  end
  
  def get_gene_data
    begin
      #get gene and attributes
      @gene = Gene.find(params[:id], :include => [:locations, [:bioentry => [:taxon_version]],[:gene_models => [:cds => [:locations, [:qualifiers => :term]],:mrna => [:locations, [:qualifiers => :term]]]],[:qualifiers => :term]])
      setup_graphics_data      
      @locus = @gene.locus_tag.value.upcase
      @bioentry = @gene.bioentry
      @annotation_terms = Term.annotation_tags.order(:name).reject{|t|t.name=='locus_tag'}      
      seq_src_ont_id = Term.seq_src_ont_id
      #TODO: Document seqfeature 'Source' uses and options for expansion
      @seq_src_term_id = Term.default_source_term.id
    rescue
      logger.error "\n\n#{$!}\n\n#{caller.join("\n")}\n\n"
    end
  end
  
  def setup_graphics_data
    @canvas_width = 3000
    @model_height = 15
    @edit_box_height = 320
    gene_size = @gene.max_end - @gene.min_start
    @gui_zoom = (gene_size/600).floor + 2    
    @view_start = @gene.min_start - (200*@gui_zoom)
    @gui_data = GeneModel.get_canvas_data(@view_start,@view_start+(@canvas_width*@gui_zoom),@gene.bioentry.id,@gui_zoom,@gene.strand)
    @depth = @gui_data.collect{|g| (g[:x2]>=(@gene.min_start-@view_start)/@gui_zoom && g[:x]<=(@gene.max_end-@view_start)/@gui_zoom) ? 1 : nil}.compact.size
    @canvas_height = ( @depth * (@model_height * 2))+10 # each model and label plus padding
    @gui_data=@gui_data.to_json
  end
  
  
end