class LocationsController < ApplicationController
  before_filter :find_location, :only => [:show, :edit, :update, :destroy]

  # GET /locations
  def index
    @locations = Biosql::Location.all
    redirect_to root_path
  # index.html.erb
  end

  # GET /_locations/1
  def show
  # show.html.erb
  end

  # GET /locations/new
  def new
    @location = Biosql::Location.new
  # new.html.erb
  end

  # GET /locations/1/edit
  def edit
  end

  # POST /locations
  def create
    @location = Biosql::Location.new(params[:location])

    respond_to do |wants|
      if @location.save
        flash[:notice] = 'Location was successfully created.'
        wants.html { redirect_to(@location) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /locations/1
  def update
    respond_to do |wants|
      if @location.update_attributes(params[:location])
        flash[:notice] = 'Location was successfully updated.'
        wants.html { params[:redirect].nil? ? redirect_to(@location) : redirect_to(JSON.parse(params[:redirect]))}
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  # DELETE /locations/1
  def destroy
    @location.destroy

    respond_to do |wants|
      wants.html { redirect_to(locations_url) }
    end
  end

  private
    def find_location
      @location = Biosql::Location.find(params[:id])
    end

end
