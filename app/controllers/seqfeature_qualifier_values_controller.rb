class SeqfeatureQualifierValuesController < ApplicationController
  
  # TODO: Remove unused actions
  # before_filter :find_seqfeature_qualifier_value, :only => [:show, :edit, :update, :destroy]
  
  # # GET /seqfeature_qualifier_values
  # def index
  #   @seqfeature_qualifier_values = Biosql::SeqfeatureQualifierValue.all
  # # index.html.erb
  # end
  # 
  # # GET /_seqfeature_qualifier_values/1
  # def show
  # # show.html.erb
  # end
  # 
  # # GET /seqfeature_qualifier_values/new
  # def new
  #   @seqfeature_qualifier_value = Biosql::SeqfeatureQualifierValue.new
  # # new.html.erb
  # end
  # 
  # # GET /seqfeature_qualifier_values/1/edit
  # def edit
  # end

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

  # # DELETE /seqfeature_qualifier_values/1
  # def destroy
  #   @seqfeature_qualifier_value.destroy
  # 
  #   respond_to do |wants|
  #     wants.html { redirect_to(seqfeature_qualifier_values_url) }
  #   end
  # end
  # 
  # private
  #   def find_seqfeature_qualifier_value
  #     @seqfeature_qualifier_value = Biosql::SeqfeatureQualifierValue.find(params[:id])
  #   end

end
