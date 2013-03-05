class AssemblysController < ApplicationController

  before_filter :find_assembly, :only => [:show, :edit, :update]

  def index
    respond_to do |wants|
      wants.html {
        order_d = (params[:d]=='up' ? 'asc' : 'desc')
        @assemblies = Assembly.includes{[species.scientific_name]}.paginate(:page => params[:page])
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
      if @assembly.update_attributes(params[:assembly])
        flash[:notice] = 'Assembly was successfully updated.'
        wants.html { redirect_to(@assembly) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  private
    def find_assembly
      @assembly = Assembly.find(params[:id])
    end

end
