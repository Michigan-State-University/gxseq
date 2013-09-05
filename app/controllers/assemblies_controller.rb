class AssembliesController < ApplicationController
  load_and_authorize_resource
  before_filter :find_assembly, :only => [:show, :edit, :update]
  before_filter :load_assoc, :only => [:edit,:update]
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
        wants.html { redirect_to edit_assembly_path(@assembly) }
      else
        logger.info "\n\n\n\n\n\n\n\n\nNO UPDATE\n\n#{@assembly.errors.inspect}\n\n\n\n"
        @samples = @assembly.samples
        wants.html { render :action => "edit" }
      end
    end
  end
  
  def concordance_sets
    @concordance_sets = Assembly.find(params[:assembly_id]).concordance_sets
    render :partial => 'concordance_set_selection', :locals => {:concordance_sets => @concordance_sets, :sample_type => params[:sample_type]}
  end
  
  private
    def find_assembly
      @assembly = Assembly.find(params[:id])
    end
    def load_assoc
      @groups = Group.all
      order_d = (params[:d]=='up' ? 'asc' : 'desc')
      @samples = @assembly.samples.includes(:group).order("#{params[:c]||'groups.name'} #{order_d}").order("samples.name")
    end
end
