class VariantsController < ApplicationController
  #filter_access_to :all
  #skip_before_filter :login_required, :only => :show

  ##custom actions - rjs
  def reload_assets
    @variant = Variant.find(params[:id])
    @variant.reload_data_from_assets
    flash[:warning]="Reloading Variant Data"
    redirect_to :action => :show
  end
  
  def graphics
    @variant = Variant.find(params[:id], :include => :bioentries_experiments)
    @bioentry = Bioentry.find(params[:bioentry_id] || @variant.bioentries_experiments.first.bioentry_id)
    render :partial => "graphics", :layout => false
  end
  
  def index
    query = (params[:query] || '').upcase
    @species = Variant.includes(:taxon_version).where{upper(name) =~ "%#{query}%"}.collect(&:taxon_version).collect(&:species).uniq
  end

  def new
    @variant = Variant.new()
    @variant.assets.build
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def create
    @variant = Variant.new(params[:variant])
    @taxon_versions = TaxonVersion.order('name asc')
    begin
      if @variant.valid?
        @variant.save
        w=@variant.assets.map(&:warnings).flatten
        if(w.empty?)
          flash[:notice]="Experiment created succesfully"
        else
          flash[:warning]="#{w.join("<br/>")}"
        end
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from Variant #{$!}\n\n"
      flash[:error]="Could not create experiment"
      redirect_to :action => :index
    end
  end

  def show
    @variant = Variant.find(params[:id])
    @bioentry = Bioentry.find(params[:bioentry_id] || @variant.bioentries_experiments.first.bioentry_id)
    respond_to do |format|
      format.html {}
      format.xml { render :layout => false }
    end
  end

  def edit
    @variant = Variant.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
  end

  def update
    @variant = Variant.find(params[:id])
    @taxon_versions = TaxonVersion.order('name asc')
    if @variant.update_attributes(params[:variant])
      flash[:notice] = 'Variant was successfully updated.'
      redirect_to(@variant)
    else
      render :action => "edit"
    end
  end

  def destroy
    @variant = Variant.find(params[:id])
    if (current_user.is_admin?)
      @variant.destroy
      flash[:warning]="Experiment #{@variant.name} has been removed"
      redirect_to :action => :index
    else
      flash[:error]="Not Permitted"
      redirect_to :action => :index
    end
  end
  
  def track_data
    begin
      jrws = JSON.parse(params[:jrws])
      param = jrws['param']
      case jrws['method']
      when 'syndicate'
        render :json => {:success => true}
      when 'range'   
        variant = Variant.find(param['experiment'])
        left = param['left']
        right = param['right']
        bioentry = Bioentry.find(param['bioentry'])
        bioentry_id = bioentry.id
        data = {}
        variant.sequence_variants.with_bioentry(bioentry_id).all(:conditions => ["pos < ? and pos > ?",right, left]).each do |v|
          data[v.class.name.downcase.to_sym] ||=[]
          data[v.class.name.downcase.to_sym] << [v.id.to_s,v.pos,v.ref.length,v.ref,v.alt,v.qual,v.depth]
        end
        render :json => {
          :success => true,
          :data => data
        }
      when 'describe'
        begin
          @bioentry = Bioentry.find(param['bioentry'])
          @sequence_variant = SequenceVariant.find(param['id'])
          render :partial => "sequence_variants/info.json"
        rescue
          render :json => {
            :success => false,
            :message => "Not Found"
          }
          logger.info "\n\n#{$!}\n\n"
        end
      when 'select_region'
        begin
          @variant = Track.find(param['id']).experiment
          @left = param['left']
          @right = param['right']
          @bioentry = Bioentry.find(param['bioentry'])
          render :partial => "variants/info.json"
        rescue
          render :json => {
            :success => true,
            :data => {
              :text => "Error"
            }
          }
          logger.info "\n\n#{$!}\n\n"
        end
      else
        render :json => {
          :success => false
        }        
      end
    rescue
      logger.info "\n\nError with Variant->track_data:#{$!}\n\n"
      render :json => {:success => false}
    end
  end
  
end
