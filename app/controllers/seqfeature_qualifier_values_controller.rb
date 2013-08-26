class SeqfeatureQualifierValuesController < ApplicationController
  # POST /seqfeature_qualifier_values
  def create
    @seqfeature_qualifier_value = Biosql::SeqfeatureQualifierValue.new(params[:biosql_seqfeature_qualifier_value])
      if @seqfeature_qualifier_value.save
        flash[:notice] = 'SeqfeatureQualifierValue was successfully created.'
        if @seqfeature_qualifier_value.seqfeature.respond_to?(:gene_model)
          redirect_to( :controller => 'biosql/feature/genes', :action => :show , :id => @seqfeature_qualifier_value.seqfeature.gene_model.gene_id )
        else
          redirect_to( :controller => 'biosql/feature/seqfeatures', :action => :show , :id => @seqfeature_qualifier_value.seqfeature.id )
        end
      else
        flash[:error] = @seqfeature_qualifier_value.errors.inspect
        if @seqfeature_qualifier_value.seqfeature.respond_to?(:gene_model)
          redirect_to( :controller => 'biosql/feature/genes', :action => :edit , :id => @seqfeature_qualifier_value.seqfeature.gene_model.gene_id )
        else
          redirect_to( :controller => 'biosql/feature/seqfeatures', :action => :edit , :id => params[:biosql_seqfeature_qualifier_value][:seqfeature_id] )
        end
      end
  end
  # PUT /seqfeature_qualifier_values/1
  def update
    respond_to do |wants|
      if @seqfeature_qualifier_value.update_attributes(params[:seqfeature_qualifier_value])
        flash[:notice] = 'SeqfeatureQualifierValue was successfully updated.'
        wants.html { redirect_to( :controller => :genes, :action => :show , :id => (@seqfeature_qualifier_value.seqfeature.respond_to?(:gene_model) ? @seqfeature_qualifier_value.seqfeature.gene_model.gene_id : @seqfeature_qualifier_value.seqfeature.id) ) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end
end
