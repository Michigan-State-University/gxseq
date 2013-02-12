class ExpressionController < ApplicationController
  before_filter :setup_form_data, :only => [:viewer]
  before_filter :setup_viewer_data, :only => [:results,:advanced_results]
  # display the selection form for samples and matrix or ratio results
  def viewer
  end
  
  # display the matrix results
  def results
    begin
      # Lookup the Experiments - Intersect with accessible experiments
      @experiments = params[:experiments].map{|e|Experiment.find(e)}.compact & @experiment_options
      experiment_symbols = @experiments.collect{|e| "exp_#{e.id}".to_sym}      
      # defaults
      params[:c]||='sum'
      # NOTE: instance variables aren't accessible within sunspot block
      order_d = @order_d
      # begin the sunspot search definition
      base_search do |s|
        # Sorting
        case params[:c]
        # dynamic 'exp_X' attribute
        when /exp_/
          s.dynamic(:normalized_counts) do
            order_by params[:c], order_d
          end
        when 'sum'
          s.dynamic(:normalized_counts) do
            order_by_function :sum, *experiment_symbols,  order_d
          end
        else
          s.order_by params[:c], order_d
        end
      end
    rescue => e
      flash.now[:warning]='Whoops! Looks like this search isn\'t working. <br/> The administrator has been notified.'

      server_error(e,"Error performing search in tools/expression_results. \n\tPerhaps Sunspot is not started, or not the correct version? 'rake sunspot:solr:start'")
      @search = nil
      @experiments =[]
    end
  end
  
  # display the ratio results
  def advanced_results
    begin
      # Lookup the Experiments Intersect with accessible experiments
      @a_experiments = params[:a_experiments].map{|e|Experiment.find(e)}.compact &  @experiment_options
      @b_experiments = params[:b_experiments].map{|e|Experiment.find(e)}.compact &  @experiment_options
      # Infinite ratio setup
      if params[:infinite_order] == 'f'
        infinity_offset = '0.000001'
      else
        params[:infinite_order] = 'l'
        infinity_offset = '-0.000001'
      end
      # defaults
      params[:c]||='ratio'
      # NOTE: instance variables aren't accessible within sunspot block
      order_d = @order_d
      a_experiment_symbols = @a_experiments.collect{|e| "exp_#{e.id}".to_sym}
      b_experiment_symbols = @b_experiments.collect{|e| "exp_#{e.id}".to_sym}
      # Search Body
      base_search do |s|
        # Sorting
        a_clause = [:div, [:sum, *a_experiment_symbols], "#{a_experiment_symbols.length}"]
        b_clause = [:div, [:sum, *b_experiment_symbols], "#{b_experiment_symbols.length}"]
        case params[:c]
        when 'exp_a'
          s.dynamic(:normalized_counts) do
            order_by_function *a_clause,  order_d
          end
        when 'exp_b'
          s.dynamic(:normalized_counts) do
            order_by_function *b_clause,  order_d
          end
        when 'ratio'
          s.dynamic(:normalized_counts) do
            # div by zero must be handled otherwise results may be invalid
            # So, we add a very small number to numerator and denominator
            order_by_function :div, [:sum,a_clause,infinity_offset], [:sum,b_clause,infinity_offset],  order_d
          end
        else
          s.order_by params[:c], order_d
        end
      end
    rescue => e
      flash.now[:warning]='Whoops! Looks like this search isn\'t working. <br/> The administrator has been notified.'
      server_error(e,"Error performing search in tools/expression_results. \n\tPerhaps Sunspot is not started? 'rake sunspot:solr:start'")
      @search = nil
      @a_experiments =[]
      @b_experiments =[]
    end
  end

  private
  # Taxon, Version and feature type lookup for every action
  def setup_form_data
    # lookup all accessible taxon versions
    # Collect from accessible experiments to avoid displaying accessible sequence that has rna_seq but none accessible to the current user
    @taxon_versions = RnaSeq.accessible_by(current_ability).includes(:taxon_version => [:blast_runs, :species => :scientific_name]).order("taxon_name.name ASC").map(&:taxon_version).uniq || []
    # set the current taxon version
    @taxon_version = @taxon_versions.find{|t_version| t_version.try(:id)==params[:taxon_version_id].to_i} || @taxon_versions.first
    # lookup the extra taxon data
    get_taxon_version_data if @taxon_version
    # get all expression features
    @feature_types = Seqfeature.facet_types_with_expression_and_taxon_version_id(@taxon_version.id) if @taxon_version
    # set the current feature
    @type_term_id ||=@feature_types.facet(:type_term_id).rows.first.try(:value) if @feature_types
  end
  
  def setup_viewer_data
    # lookup taxon version
    @taxon_version = TaxonVersion.accessible_by(current_ability).where(:id => params[:taxon_version_id]).first
    # redirect if none available
    unless @taxon_version
      redirect_to expression_viewer_path
      return
    end
    # lookup the extra taxon data
    get_taxon_version_data
    # build the grouped select
    setup_definition_select
    # set default search parameters
    setup_defaults
  end
  
  #returns rna_seq,features with expression,and blast_runs associated with this taxon version
  def get_taxon_version_data
    begin
      # set the type_term_id
      @type_term_id = params[:type_term_id]
      # get the experiments
      @experiment_options = @taxon_version.rna_seqs.accessible_by(current_ability).order('experiments.name')
      # find any blasts
      @blast_runs = @taxon_version.blast_runs
      # set the taxon_version param for search block 
      params[:taxon_version_id] ||= @taxon_version.try(:id)
    rescue => e
      logger.info "\n***Error: Could not build version and features in expression controller:\n#{e}\n"
      server_error(e,"Could not build version and features")
    end
  end
  
  # options for grouped select
  def setup_definition_select
    @group_select_options = {
      'Combined' => [['Description','description'],['Everything','full_description']],
      "Blast Reports" => @blast_runs.collect{|run|[run.name,run.name_with_id]},
      'Annotation' => [['Function','function'],['Product','product']]
    }
    # Get all the custom terms in use
    @terms = Term.includes(:ontology,[:qualifiers => [:seqfeature => :bioentry]]).where{ (seqfeature.type_term_id == my{@type_term_id}) & (bioentry.taxon_version_id == my{@taxon_version.id}) & (ontology_id.in(Term.custom_ontologies))}
    @terms.each do |term|
      @group_select_options[term.ontology.name] ||= []
      @group_select_options[term.ontology.name] << [term.name, term.name_with_id]
    end
  end
  # defaults
  def setup_defaults
    params[:per_page]||=50
    params[:definition_type]||= @taxon_version.is_genome? ? 'description' : @blast_runs.first.name_with_id
    # setup order
    case params[:d]
    when 'ASC','asc','up'
      @order_d = :asc
    else
      @order_d = :desc
    end
  end

  # Shared search setup
  def base_search
    # Find minimum set of id ranges accessible by current user
    authorized_id_set = current_user.authorized_seqfeature_ids
    # Set to -1 if no items are found. This will force empty search results
    authorized_id_set=[-1] if authorized_id_set.empty?
    # start base search block
    @search = Seqfeature.search do |s|
      # Auth
      s.any_of do |any_s|
        authorized_id_set.each do |id_range|
          any_s.with :id, id_range
        end
      end
      # limit to the current taxon_version
      s.with(:taxon_version_id, params[:taxon_version_id].to_i)
      # limit to the supplied type
      s.with(:type_term_id, params[:type_term_id].to_i)
      # Search Filters
      unless params[:locus_tag].blank?
        s.with :locus_tag, params[:locus_tag]
      end
      # Text Search
      unless params[:keywords].blank?
        s.fulltext params[:keywords], :fields => [params[:definition_type]+'_text', :locus_tag_text], :highlight => true
      end
      # Remove empty
      case params[:show_blank]
      # don't show empty definitions
      when 'n'
        s.without params[:definition_type], nil
      # only show empty definitions
      when 'e'
        s.with params[:definition_type], nil
      end
      # Favorites
      case params[:favorites_filter]
      when 'user'
        s.with :favorite_user_ids, current_user.id
      when 'all'
        s.without :favorite_user_ids, nil
      end
      # paging
      s.paginate(:page => params[:page], :per_page => params[:per_page])
      # scope to id
      # we use this search so we can insert a highlighted text result after an update
      if(params[:seqfeature_id])
        s.with :id, params[:seqfeature_id]
      end
      yield(s)
    end
    # Check XHR
    # we are assuming all xhr search results with a seqfeature_id are requests for an in place update
    # if there is a result, only render the first
    if params[:seqfeature_id] and request.xhr?
      if @search.total == 0
        render :text => 'not found..'
      else
        @search.each_hit_with_result do |hit,feature|
          render :partial => 'hit_definition', :locals => {:hit => hit, :feature => feature, :definition_type => params[:definition_type]}
          break
        end
      end
    end
  end

end