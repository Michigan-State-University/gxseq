class SeqfeaturesController < ApplicationController
  before_filter :find_seqfeature, :except => [:index, :new, :create]
  before_filter :get_feature_data, :only => [:edit,:update]
  authorize_resource
  # GET /seqfeatures
  def index
    # Defaults
    params[:page]||=1
    params[:c]||='taxon_version_name_with_version'
    order_d = (params[:d]=='down' ? 'desc' : 'asc')
    @presence_items = presence_items = ['gene_name','function','product']
    # Filter setup
    @taxon_versions = TaxonVersion.accessible_by(current_ability).includes(:taxon => :scientific_name).order('taxon_name.name')
    # Find minimum set of id ranges accessible by current user. Set to -1 if no items are found. This will force empty search results
    authorized_id_set = Seqfeature.accessible_by(current_ability).select_ids.to_ranges
    authorized_id_set=[-1] if authorized_id_set.empty?
    # Begin block
    @search = Seqfeature.search do
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
      # Filters
      with :taxon_version_id, params[:taxon_version_id] unless params[:taxon_version_id].blank?
      with :strand, params[:strand] unless params[:strand].blank?
      with(:type_term_id, params[:type_term_id]) unless params[:type_term_id].blank?
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
      # scope to id
      # we use this search so we can insert a highlighted text result after an update
      if(params[:seqfeature_id])
        with :id, params[:seqfeature_id]
      end
      # Facets (group counts)
      facet(:type_term_id)
      facet(:strand)
    end
    
    # Check XHR
    # we are assuming all xhr search results with a seqfeature_id are requests for an in place update
    # if there is a result, only render the first
    if params[:seqfeature_id] and request.xhr?
      if @search.total == 0
        render :text => 'not found..'
      else
        @search.each_hit_with_result do |hit,feature|
          render :partial => 'hit_definition', :locals => {:hit => hit, :feature => feature}
          break
        end
      end
    end
    
  end

  # GET /_seqfeatures/1
  def show
    authorize! :read, @seqfeature
    @format = params[:fmt] || 'standard'
    begin
    # Gene features have special show pages
    if @seqfeature.kind_of?(Gene)
      redirect_to gene_path(@seqfeature)
    end
    case @format
    when 'standard'
      setup_graphics_data
      @ontologies = Term.annotation_ontologies
    when 'genbank'
      #NOTE:  Find related features (by locus tag until we have a parent<->child relationship)
      @features = @seqfeature.find_related_by_locus_tag
      @ontologies = [Ontology.find(Term.ano_tag_ont_id)]
    when 'history'
      @changelogs = Version.order('id desc').where(:parent_id => @seqfeature.id).where(:parent_type => @seqfeature.class.name)
    when 'expression'
      @feature_counts = @seqfeature.feature_counts.accessible_by(current_ability)
      @graph_data = FeatureCount.create_graph_data(@feature_counts)
    when 'blast'
      @blast_reports = @seqfeature.blast_reports
      params[:blast_report_id]||=@blast_reports.first.id
      @blast_report = BlastReport.find(params[:blast_report_id])
      @blast_run = @blast_report.blast_run
    end
    rescue
      @seqfeature = nil
    end
  end

  # GET /seqfeatures/new
  def new
  end

  # GET /seqfeatures/1/edit
  def edit
    # Gene features have special edit pages
    authorize! :update, @seqfeature
    if request.xhr?
      setup_xhr_form
      #@seqfeature.qualifiers.build
      render :partial => 'form'
    elsif @seqfeature.kind_of?(Gene)
      redirect_to edit_gene_path(@seqfeature)
    end
  end

  # POST /seqfeatures
  def create
    respond_to do |wants|
      if @seqfeature.save
        flash[:notice] = 'Seqfeature was successfully created.'
        wants.html { redirect_to(@seqfeature) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /seqfeatures/1
  def update
    authorize! :update, @seqfeature
    respond_to do |wants|
      if @seqfeature.update_attributes(params[:seqfeature])
        if request.xhr?
          wants.html { render :text => "success" }
        else
          flash[:notice] = 'Seqfeature was successfully updated.'
          wants.html { redirect_to(@seqfeature.becomes(Seqfeature)) }
        end
      else
        if request.xhr?
          setup_xhr_form
          wants.html { render :partial => "form" }
        else
          wants.html { render :action => "edit" }
        end
      end
    end
  end

  # DELETE /seqfeatures/1
  def destroy
    @seqfeature.destroy
    respond_to do |wants|
      wants.html { redirect_to(params[:return_to]||seqfeatures_url) }
    end
  end

  # Add or Remove this seqfeature as a favorite for the given user, and reindex
  def toggle_favorite
    #Note: is it right to have the image here?
    if favorite_feature = FavoriteSeqfeature.find_by_favorite_item_id_and_user_id(@seqfeature.id,current_user.id)
      favorite_feature.destroy
      @new_favorite_image = 'star_gray.png'
    else
      current_user.seqfeatures << @seqfeature
      @new_favorite_image = 'star.png'
    end
    @seqfeature.index!
    # if request.xhr?
    #   render :partial => 'seqfeatures/update_favorite', :locals => {:is_favorite => true, :feature => @seqfeature}
    # else
    #   redirect_to seqfeature_path(@seqfeature)
    # end
  end

  private
    def find_seqfeature
      @seqfeature = Seqfeature.find(params[:id], :include => [:locations,[:bioentry => [:taxon_version]]])
    end
    # TODO: refactor this method is duplicated from genes_controller
    def get_feature_data
      @format='edit'
      begin
        #get gene and attributes
        @seqfeature = Seqfeature.find(params[:id], :include => [:locations,[:qualifiers => :term],[:bioentry => [:taxon_version]]])
        setup_graphics_data
        @locus = @seqfeature.locus_tag.value.upcase
        @bioentry = @seqfeature.bioentry
        @annotation_terms = Term.annotation_tags.order(:name).reject{|t|t.name=='locus_tag'}
        seq_src_ont_id = Term.seq_src_ont_id
        @seq_src_term_id = Term.default_source_term.id
      rescue
        logger.error "\n\n#{$!}\n\n#{caller.join("\n")}\n\n"
      end
    end

    def setup_xhr_form
      @skip_locations=@extjs=true
      @blast_reports = @seqfeature.blast_reports
      @changelogs = Version.order('id desc').where(:parent_id => @seqfeature.id).where(:parent_type => @seqfeature.class.name)
      @changelogs = @changelogs.where{item_type != 'Location'}.where{item_type != 'GeneModel'}
    end

    def setup_graphics_data
      @canvas_width = 2500
      @model_height = 15
      @edit_box_height = 320
      min_width = 700
      feature_size = @seqfeature.max_end - @seqfeature.min_start
      @pixels = [(min_width / (feature_size*1.1)).floor,1].max
      @bases = [((feature_size*1.1) / min_width).floor,1].max
      @view_start = @seqfeature.min_start - (feature_size*0.05).floor
      @view_stop = (@seqfeature.min_start+(feature_size*1.05)).ceil
      @graphic_data = Seqfeature.get_track_data(@view_start,@view_stop,@seqfeature.bioentry_id,{:feature => @seqfeature})
      @depth = 3
      @canvas_height = ( @depth * (@model_height * 2))+10 # each model and label plus padding
      @graphic_data=@graphic_data.to_json
    end
end
