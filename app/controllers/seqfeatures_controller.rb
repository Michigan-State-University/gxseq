class SeqfeaturesController < ApplicationController

  before_filter :find_seqfeature, :only => [:show, :edit, :update, :destroy]

  # GET /seqfeatures
  def index
    @search = Seqfeature.search do
      keywords params[:keywords], :fields => [:qualifier_values], :highlight => true
      facet(:display_name)
      facet(:type_term_id)
      with(:type_term_id, params[:type_term_ids]) unless params[:type_term_ids].blank?
      with(:locus_tag, params[:locus_tag]) unless params[:locus_tag].blank?
      paginate(:page => params[:page])
    end
    
  # index.html.erb
  end

  # GET /_seqfeatures/1
  def show
  # show.html.erb
  end

  # GET /seqfeatures/new
  def new
    @seqfeature = Seqfeature.new
  # new.html.erb
  end

  # GET /seqfeatures/1/edit
  def edit
  end

  # POST /seqfeatures
  def create
    @seqfeature = Seqfeature.new(params[:seqfeature])

    respond_to do |wants|
      if @seqfeature.save
        flash[:notice] = 'Seqfeature was successfully created.'
        wants.html { redirect_to(@seqfeature) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /seqfeatures/1
  def update
    respond_to do |wants|
      if @seqfeature.update_attributes(params[:seqfeature])
        flash[:notice] = 'Seqfeature was successfully updated.'
        wants.html { redirect_to(@seqfeature) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  # DELETE /seqfeatures/1
  def destroy
    @seqfeature.destroy

    respond_to do |wants|
      wants.html { redirect_to(seqfeatures_url) }
    end
  end

  private
    def find_seqfeature
      @seqfeature = Seqfeature.find(params[:id])
    end

end
