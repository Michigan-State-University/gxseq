class Admin::Biosql::TermsController < ApplicationController

  before_filter :find_term, :only => [:show, :edit, :update, :destroy]

  # GET /admin::_terms
  def index
    @terms = ::Biosql::Term.scoped
    @ontologies = ::Biosql::Ontology.all
    unless params[:ontology_id].blank?
      @terms = @terms.where{ontology_id == my{params[:ontology_id]}}
    end
    unless params[:query].blank?
      @terms = @terms.where{name=~my{params[:query]}}
    end
    # Order
    if params[:d] && (params[:d] == 'down' || params[:d] == 'desc')
      order_d = 'DESC'
    else
      order_d = 'ASC'
    end
    order_col = params[:c] || 'name'
    @terms = @terms.order("#{order_col} #{order_d}")
  # index.html.erb
  end

  # GET /_admin::_terms/1
  def show
  # show.html.erb
  end

  # GET /admin::_terms/new
  def new
    @term = ::Biosql::Term.new
  # new.html.erb
  end

  # GET /admin::_terms/1/edit
  def edit
  end

  # POST /admin::_terms
  def create
    @term = ::Biosql::Term.new(params[:biosql_term])

    respond_to do |wants|
      if @term.save
        flash[:notice] = 'Term was successfully created.'
        wants.html { redirect_to(admin_biosql_terms_url) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /admin::_terms/1
  def update
    respond_to do |wants|
      if @term.update_attributes(params[:biosql_term])
        flash[:notice] = 'Term was successfully updated.'
        wants.html { redirect_to(admin_biosql_terms_url) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  # DELETE /admin::_terms/1
  def destroy
    term_name = @term.name
    associates = @term.bioentry_qualifer_values.count + @term.seqfeature_sources.count + @term.seqfeature_types.count + @term.qualifiers.count + @term.locations.count + @term.sample_traits.count
    if(associates > 0)
      flash[:warning]="'#{term_name}' still has #{associates} items attached. You cannot remove it"
    else
      flash[:warning]="#{term_name} has been removed"
      @term.destroy
    end
    respond_to do |wants|
      
      wants.html { redirect_to(admin_biosql_terms_url) }
    end
  end

  private
    def find_term
      @term = ::Biosql::Term.find(params[:id])
    end

end
