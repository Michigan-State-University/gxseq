class Biosql::OntologiesController < ApplicationController
  authorize_resource
  
  def show
    @ontology = Biosql::Ontology.find(params[:id])
  end
end