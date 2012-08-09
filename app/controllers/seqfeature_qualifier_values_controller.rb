class SeqfeatureQualifierValuesController < ApplicationController

  before_filter :find_seqfeature_qualifier_value, :only => [:show, :edit, :update, :destroy]

  # GET /seqfeature_qualifier_values
  def index
    @seqfeature_qualifier_values = SeqfeatureQualifierValue.all
  # index.html.erb
  end

  # GET /_seqfeature_qualifier_values/1
  def show
  # show.html.erb
  end

  # GET /seqfeature_qualifier_values/new
  def new
    @seqfeature_qualifier_value = SeqfeatureQualifierValue.new
  # new.html.erb
  end

  # GET /seqfeature_qualifier_values/1/edit
  def edit
  end

  # POST /seqfeature_qualifier_values
  def create
    @seqfeature_qualifier_value = SeqfeatureQualifierValue.new(params[:seqfeature_qualifier_value])

    respond_to do |wants|
      if @seqfeature_qualifier_value.save
        flash[:notice] = 'SeqfeatureQualifierValue was successfully created.'
        wants.html { redirect_to( :controller => :genes, :action => :show , :id => (@seqfeature_qualifier_value.seqfeature.id) ) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /seqfeature_qualifier_values/1
  def update
    respond_to do |wants|
      if @seqfeature_qualifier_value.update_attributes(params[:seqfeature_qualifier_value])
        flash[:notice] = 'SeqfeatureQualifierValue was successfully updated.'
        wants.html { redirect_to( :controller => :genes, :action => :show , :id => (@seqfeature_qualifier_value.seqfeature.id) ) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  # DELETE /seqfeature_qualifier_values/1
  def destroy
    @seqfeature_qualifier_value.destroy

    respond_to do |wants|
      wants.html { redirect_to(seqfeature_qualifier_values_url) }
    end
  end

  private
    def find_seqfeature_qualifier_value
      @seqfeature_qualifier_value = SeqfeatureQualifierValue.find(params[:id])
    end

end
