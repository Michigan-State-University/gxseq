class Biosql::SeqfeatureQualifierValuesController < ApplicationController
  # POST /seqfeature_qualifier_values
  def create
    @seqfeature_qualifier_value = Biosql::SeqfeatureQualifierValue.new(params[:biosql_seqfeature_qualifier_value])
      if @seqfeature_qualifier_value.save
        flash[:notice] = 'SeqfeatureQualifierValue was successfully created.'
        redirect_to( seqfeature_path(@seqfeature_qualifier_value.seqfeature_id) )
      else
        flash[:error] = @seqfeature_qualifier_value.errors.inspect
        wants.html { redirect_to( seqfeature_path(@seqfeature_qualifier_value.seqfeature_id) ) }
      end
  end
  # PUT /seqfeature_qualifier_values/1
  def update
    @seqfeature_qualifier_value = Biosql::SeqfeatureQualifierValue.find(params[:id])
    respond_to do |wants|
      if @seqfeature_qualifier_value.update_attributes(params[:biosql_seqfeature_qualifier_value])
        flash[:notice] = 'SeqfeatureQualifierValue was successfully updated.'
        wants.html { redirect_to( seqfeature_path(@seqfeature_qualifier_value.seqfeature_id) ) }
      else
        flash[:error] = @seqfeature_qualifier_value.errors.inspect
        wants.html { redirect_to( seqfeature_path(@seqfeature_qualifier_value.seqfeature_id) ) }
      end
    end
  end
end
