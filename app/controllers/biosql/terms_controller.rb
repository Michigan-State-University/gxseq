class Biosql::TermsController < ApplicationController
  authorize_resource
  
  def new
    @term = Biosql::Term.find(params[:id])
  end
  
  def create
    @term = ::Biosql::Term.new(params[:biosql_term])
    respond_to do |wants|
      if @term.save
        flash[:notice] = 'Term Added'
        wants.html { redirect_to( biosql_ontology_url(@term.ontology) ) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end
  
end