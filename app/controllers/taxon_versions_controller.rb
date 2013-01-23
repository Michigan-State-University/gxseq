class TaxonVersionsController < ApplicationController

  before_filter :find_taxon_version, :only => [:show, :edit, :update]

  def index
    respond_to do |wants|
      wants.html {
        order_d = (params[:d]=='up' ? 'asc' : 'desc')
        @taxon_versions = TaxonVersion.includes{[species.scientific_name]}.paginate(:page => params[:page])
        .order("taxon_name.name #{order_d}, version #{order_d}")
      }
    end
  end
  
  def show  
  end

  def edit
  end

  def update
    respond_to do |wants|
      if @taxon_version.update_attributes(params[:taxon_version])
        flash[:notice] = 'TaxonVersion was successfully updated.'
        wants.html { redirect_to(@taxon_version) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  private
    def find_taxon_version
      @taxon_version = TaxonVersion.find(params[:id])
    end

end
