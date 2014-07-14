class ExpressionController < ApplicationController
  before_filter :setup_form_data, :only => [:viewer]
  before_filter :setup_results_data, :only => [:results,:advanced_results,:parallel_graph]
  # display the selection form for samples and matrix or ratio results
  def viewer
    params[:fmt]||='viewer'
  end
   
  # display the matrix results
  def results
    begin
    # Lookup the Samples - Intersect with accessible samples
    @samples = (params[:samples]||[]).map{|e|Sample.find(e)}.compact & @sample_options
    respond_to do |format|
      # Base html query
      format.html{
        @search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@samples,params) do |s|
          s.paginate(:page => params[:page], :per_page => params[:per_page])
        end
        # Check for seqfeature update
        check_xhr
      }
      format.csv{
        # Use the initial query to get total pages
        search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@samples,params) do |s|
          s.paginate(:page => 1, :per_page => 1000)
        end
        current_page = 1
        total_pages = search.hits.total_pages
        # use custom proc for response body
        # NOTE: change to streaming Enumerator for rails 3.2
        self.response_body = proc {|resp, out|
          # Add the header
          out.write (['Locus','Definition']+@blast_runs.map(&:name)+@samples.map(&:name)+['Sum']).to_csv
          # Write the first page
          out.write Biosql::Feature::Seqfeature.matrix_search_to_csv(search,@samples,@blast_runs,params)
          # Write any additional pages
          while(current_page < total_pages)
            current_page+=1
            search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@samples,params) do |s|
              s.paginate(:page => current_page, :per_page => 1000)
            end
            out.write Biosql::Feature::Seqfeature.matrix_search_to_csv(search,@samples,@blast_runs,params)
          end
        }
      }
    end
    rescue => e
      flash.now[:warning]='Whoops! Looks like this search isn\'t working. <br/> The administrator has been notified.'
      server_error(e,"Error performing search in tools/expression_results. \n\tPerhaps Sunspot is not started, or not the correct version? 'rake sunspot:solr:start'")
      @search = nil
      @samples||=[]
    end
  end
  
  # display the ratio results
  def advanced_results
    begin
    # Lookup the Samples and intersect with accessible samples
    @a_samples = params[:a_samples].map{|e|Sample.find(e)}.compact &  @sample_options
    @b_samples = params[:b_samples].map{|e|Sample.find(e)}.compact &  @sample_options
    respond_to do |format|
      # Base html query
      format.html{
        @search = Biosql::Feature::Seqfeature.ratio_search(current_ability,@assembly.id,@type_term_id,@a_samples,@b_samples,params) do |s|
          s.paginate(:page => params[:page], :per_page => params[:per_page])
        end
        # Check for seqfeature update
        check_xhr
      }
      # Streaming csv render
      format.csv{
        # Use the initial query to get total pages
        search = Biosql::Feature::Seqfeature.ratio_search(current_ability,@assembly.id,@type_term_id,@a_samples,@b_samples,params) do |s|
          s.paginate(:page => 1, :per_page => 1000)
        end
        current_page = 1
        total_pages = search.hits.total_pages
        # use custom proc for response body
        # NOTE: change to streaming Enumerator for rails 3.2
        self.response_body = proc {|resp, out|
          # Add the header
          out.write (['Locus','Definition']+@blast_runs.map(&:name)+['Set A','Set B','A / B']).to_csv
          # Write the first page
          out.write Biosql::Feature::Seqfeature.ratio_search_to_csv(search,@a_samples,@b_samples,@blast_runs,params)
          # Write any additional pages
          while(current_page < total_pages)
            current_page+=1
            search = Biosql::Feature::Seqfeature.ratio_search(current_ability,@assembly.id,@type_term_id,@a_samples,@b_samples,params) do |s|
              s.paginate(:page => current_page, :per_page => 1000)
            end
            out.write Biosql::Feature::Seqfeature.ratio_search_to_csv(search,@a_samples,@b_samples,@blast_runs,params)
          end
        }
      }
    end
    rescue => e
      flash.now[:warning]='Whoops! Looks like this search isn\'t working. <br/> The administrator has been notified.'
      server_error(e,"Error performing search in tools/expression_results. \n\tPerhaps Sunspot is not started? 'rake sunspot:solr:start'")
      @search = nil
      @a_samples||=[]
      @b_samples||=[]
    end
  end
  
  def parallel_graph
    # Lookup the Samples - Intersect with accessible samples
    @samples = params[:samples].map{|e|Sample.find(e)}.compact & @sample_options
    @search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@samples,params) do |s|
      s.paginate(:page => params[:page], :per_page => 100)
    end
  end
  
  private
  # Sets assembly and feature type options for viewer form
  def setup_form_data
    # lookup all accessible taxon versions
    # Collect from accessible samples to avoid displaying accessible sequence that has rna_seq but none accessible to the current user
    @assemblies = RnaSeq.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).order("taxon_name.name ASC").map(&:assembly).uniq || []
    # set the current assembly
    @assembly = @assemblies.find{|t_version| t_version.try(:id)==params[:assembly_id].to_i} || @assemblies.first
    # lookup the extra taxon data
    get_assembly_data if @assembly
    # get all expression features
    @feature_types = Biosql::Feature::Seqfeature.facet_types_with_expression_and_assembly_id(@assembly.id) if @assembly
    # setup default type_term if not supplied in params
    @type_term_id ||=@feature_types.facet(:type_term_id).rows.first.try(:value) if @feature_types
  end
  # Sets assembly, samples and selection dropdowns for search results displays
  def setup_results_data
    # lookup taxon versionand redirect if none available
    @assembly = Assembly.accessible_by(current_ability).where(:id => params[:assembly_id]).first
    unless @assembly
      redirect_to expression_viewer_path
      return
    end
    # lookup the extra taxon data
    get_assembly_data
    # set default search parameters
    setup_options
  end
  #returns rna_seq,features with expression,and blast_runs associated with this taxon version
  def get_assembly_data
    begin
      # set the type_term_id
      @type_term_id = params[:type_term_id]
      # get the samples
      @sample_options = @assembly.rna_seqs.accessible_by(current_ability).order('samples.name')
      # find any blasts
      @blast_runs = @assembly.blast_runs
    rescue => e
      logger.info "\n***Error: Could not build version and features in expression controller:\n#{e}\n"
      server_error(e,"Could not build version and features")
    end
  end
  # defaults
  def setup_options
    params[:per_page]||=50
    params[:value_type]||='normalized_counts'
    @value_options = {'Normalized Counts' => 'normalized_counts', 'Total Counts' => 'counts', 'Unique Counts' => 'unique_counts'}
    # Setup the definition select list
    terms = []
    @group_select_options = {
      "Blast Reports" => @blast_runs.collect{|run|terms<<"blast_#{run.id}";["#{run.blast_iterations.count}: #{run.name}","blast_#{run.id}"]}
    }
    # Get all the annotations in use by an assembly feature.
    qual_facet = Biosql::Feature::Seqfeature.facet_qualifier_terms_by_type_and_assembly_id(params[:type_term_id],@assembly.id)
    top_count = qual_facet.facet(:qualifier_term_ids).rows.first.count
    qual_facet.facet(:qualifier_term_ids).rows.each do |row|
      if (row.count >0 ) && (term = Biosql::Term.find_by_term_id(row.value))
        @group_select_options[term.ontology.name]||=[]
        @group_select_options[term.ontology.name] << ["#{row.count}: #{term.name}", "term_#{term.id}"]
        terms << "term_#{term.id}"
      end
    end
    # select all by default
    if params[:definition_type].blank? and params[:multi_definition_type].blank?
      params[:multi_definition_type]=terms
    end
  end
  
  # Check XHR
  # we are assuming all xhr search results with a seqfeature_id are requests for an in place update
  # if there is a result, only render the first
  def check_xhr
    if params[:seqfeature_id] and request.xhr?
      if @search.total == 0
        render :text => '*Does not match search'
      else
        @search.each_hit_with_result do |hit,feature|
          render :partial => 'hit_definition', :locals => {:hit => hit, :feature => feature, :definition_type => params[:definition_type], :multi_definition_type => params[:multi_definition_type]}
          break
        end
      end
      return
    end
  end

end