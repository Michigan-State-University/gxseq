class Admin::OntologiesController < ApplicationController

  before_filter :find_ontology, :only => [:show, :edit, :update, :destroy]

  # GET /ontologies
  def index
    @ontologies = Biosql::Ontology.scoped
    unless params[:query].blank?
      @ontologies = @ontologies.where{(upper(name)=~my{"%#{params[:query].upcase}%"})|(upper(definition)=~my{"%#{params[:query].upcase}%"})}
    end
  # index.html.erb
  end

  # GET /_ontologies/1
  def show
  # show.html.erb
  end

  # GET /ontologies/new
  def new
    @ontology = Biosql::Ontology.new
  # new.html.erb
  end

  # GET /ontologies/1/edit
  def edit
  end

  # POST /ontologies
  def create
    @ontology = Biosql::Ontology.new(params[:ontology])

    respond_to do |wants|
      if @ontology.save
        flash[:notice] = 'Ontology was successfully created.'
        wants.html { redirect_to(admin_ontologies_url) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /ontologies/1
  def update
    respond_to do |wants|
      if @ontology.update_attributes(params[:ontology])
        flash[:notice] = 'Ontology was successfully updated.'
        wants.html { redirect_to(admin_ontologies_url) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  # DELETE /ontologies/1
  def destroy
    if(@ontology.terms.size > 0)
      flash[:warning]="This ontology still has #{@ontology.terms.size} terms attached. You cannot remove it"
    else
      @ontology.destroy
    end
    respond_to do |wants|
      wants.html { redirect_to(admin_ontologies_url) }
    end
  end

  private
    def find_ontology
      @ontology = Biosql::Ontology.find(params[:id])
    end

end
