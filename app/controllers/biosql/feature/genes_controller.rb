class Biosql::Feature::GenesController < ApplicationController
  authorize_resource :class => "Biosql::Feature::Gene"
  before_filter :lookup_gene, :only => [:show]
  before_filter :get_gene_data, :only => [:edit, :update]
  before_filter :new_gene_data, :only => [:new,:create]
  #TODO: Refactor controller. Split into genes_controller gene_models_controller. They are mixed right now...
  def index
    # Defaults
    params[:page]||=1
    params[:c]||='assembly_name_with_version'
    order_d = (params[:d]=='down' ? 'desc' : 'asc')
    @presence_items = presence_items = ['gene_name','function','product']
    # Filter setup
    @assemblies = Assembly.accessible_by(current_ability).includes(:taxon => :scientific_name).order('taxon_name.name')
    # Find minimum set of id ranges accessible by current user. Set to -1 if no items are found. This will force empty search results
    authorized_id_set = current_ability.authorized_gene_model_ids
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
      with :assembly_id, params[:assembly_id] unless params[:assembly_id].blank?
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
    # Create a gene template for the bioentry
    if @bioentry
      @gene = Biosql::Feature::Gene.new(:bioentry => @bioentry)
      # Add a new gene model
      @gene.gene_models.build
      # Add a locus tag
      @gene.qualifiers.build(:term => Biosql::Term.annotation_tags.where(:name => 'locus_tag').first)
      # Add a location
      @gene.locations.build
    end
  end
  
  def create
    begin
      @gene = Biosql::Feature::Gene.new(params[:biosql_feature_gene])
      @bioentry = @gene.bioentry
      @assembly = @gene.bioentry.assembly if @bioentry
      if(@gene.valid?)
        Biosql::Feature::Gene.transaction do
          @gene.save
          redirect_to [:edit,@gene], :notice => "Gene Created Successfully"
        end
      else
        # add gene model
        @gene.gene_models.build unless @gene.gene_models.length > 0
        # add locus
        @gene.qualifiers.build(:term => Biosql::Term.annotation_tags.where(:name => 'locus_tag').first) unless @gene.locus_tag
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
    @seqfeature = @gene
    @format = params[:fmt] || 'standard'
    begin
    case @format
    when 'variants'
      @variant_window = [(params[:v_win].to_i || 0),1000].min
      @variant_format = params[:v_fmt] || 'fasta'
    when 'standard'
      setup_graphics_data
    when 'genbank'
      #Note: Find related features (by locus tag until we have a parent<->child relationship)
      @features = @gene.find_related_by_locus_tag
    when 'history'
      @changelogs = Version.order('id desc').where(:parent_id => @gene.id).where(:parent_type => 'Biosql::Feature::Gene')
    when 'expression'
      assembly = @gene.bioentry.assembly
      @trait_types = @gene.bioentry.assembly.trait_types
      @trait_types = assembly.trait_types
      if params[:trait_type_id]
        if current_user
          current_user.preferred_trait_group_id = params[:trait_type_id], assembly
          current_user.save
        end
        @trait_type_id = params[:trait_type_id]
      else
        if current_user
          @trait_type_id = current_user.preferred_trait_group_id(assembly)
        end
      end
      @feature_counts = @gene.feature_counts.accessible_by(current_ability).includes(:sample).order("samples.name")
    when 'coexpression'
      @feature_counts = @gene.feature_counts.accessible_by(current_ability).includes(:sample).order("samples.name")
    when 'blast'
      @blast_reports = @gene.blast_reports
      params[:blast_report_id]||=@blast_reports.first.id
      @blast_report = BlastReport.find_by_id(params[:blast_report_id])
      @blast_run = @blast_report.try(:blast_run)
    end
    rescue => e
      logger.info "\n#{e}\n\n#{e.backtrace.inspect}\n\n"
      @gene = nil
    end
    authorize! :read, @gene
  end
  
  def edit
    @format = 'edit'
    authorize! :update, @gene
    if @gene.locations.empty?
      @gene.locations.build
    end
  end
  
  def update
    authorize! :update, @gene
    begin
      Biosql::Feature::Gene.transaction do
        if(@gene.update_attributes(params[:biosql_feature_gene]))
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
    authorize! :create, Biosql::Feature::Gene.new
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name').accessible_by(current_ability)
    @src_terms = Biosql::Term.source_tags
    if params[:bioentry_id]
      @bioentry=Biosql::Bioentry.find_by_bioentry_id(params[:bioentry_id])
      @assembly = @bioentry.assembly
    elsif params[:assembly_id]
      @assembly = Assembly.find_by_id(params[:assembly_id])
      @bioentry = @assembly.bioentries.first if @assembly
    end
  end
  
  def lookup_gene
    # See if we have a locus or id
    gene_id = Biosql::Feature::Gene.with_locus_tag(params[:id]).first.try(:id) || params[:id]
    # Lookup gene by id
    @gene = Biosql::Feature::Gene.where(:seqfeature_id => gene_id)
      .includes(
      [ 
        :locations,
        [:qualifiers => :term],
        [:bioentry => [:assembly]],
        [:gene_models => [:cds => [:locations, [:qualifiers => :term]],:mrna => [:locations, [:qualifiers => :term]]]],
      ])
      .first
    # Lookup all genes with the same locus tag for warning display
    @genes = Biosql::Feature::Gene.with_locus_tag( @gene.locus_tag.value)
  end
  
  def get_gene_data
    begin
      #get gene and attributes
      @gene = Biosql::Feature::Gene.find(params[:id], :include => [:locations, [:bioentry => [:assembly]],[:gene_models => [:cds => [:locations, [:qualifiers => :term]],:mrna => [:locations, [:qualifiers => :term]]]],[:qualifiers => :term]])
      unless @gene.locations.empty?
        setup_graphics_data
      end
      @locus = @gene.locus_tag.value.upcase
      @bioentry = @gene.bioentry
      @annotation_terms = Biosql::Term.annotation_tags.order(:name).reject{|t|t.name=='locus_tag'}
      @src_terms = Biosql::Term.source_tags      
      seq_src_ont_id = Biosql::Term.seq_src_ont_id
      @seq_src_term_id = Biosql::Term.default_source_term.id
    rescue => e
      logger.error "\n\n#{$!}\n\n#{e.backtrace.join("\n")}\n\n"
    end
  end
  
  def setup_graphics_data
    @canvas_width = 3000
    @model_height = 15
    @edit_box_height = 320
    limit = 1000
    gene_size = @gene.max_end - @gene.min_start
    @gui_zoom = (gene_size/700).floor + 2    
    @view_start = @gene.min_start - (50*@gui_zoom)
    @gui_data = GeneModel.get_canvas_data(@view_start,@view_start+(@canvas_width*@gui_zoom),@gene.bioentry.id,@gui_zoom,@gene.strand,limit)
    @depth =  (@gui_data.collect{|g|g[:variants]}.max||0) + 1
    #@depth = @gui_data.collect{|g| (g[:x2]>=(@gene.min_start-@view_start)/@gui_zoom && g[:x]<=(@gene.max_end-@view_start)/@gui_zoom) ? 1 : nil}.compact.size
    @canvas_height = ( @depth * (@model_height * 2))+10 # each model and label plus padding
    @gui_data=@gui_data.to_json
  end
  
  
end