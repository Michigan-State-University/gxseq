class VariantsController < ApplicationController
  require 'will_paginate/array'
  before_filter :get_variants, :only => [:show, :graphics]
  
  ##custom actions - rjs
  def initialize_experiment
    @variant = Variant.find(params[:id])
    @variant.initialize_experiment
    render :update do |page|
      page.replace_html 'initialize_experiment', "Job Started. Refresh to view updates in the console."
    end
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
    if (current_user.is_admin? || current_user.owns?(@variant))
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
        sample = param['sample']
        left = param['left']
        right = param['right']
        bioentry = Bioentry.find(param['bioentry'])
        bioentry_id = bioentry.id
        be = variant.bioentries_experiments.find_by_bioentry_id(bioentry_id)
        data = []
        variant.get_data(be.sequence_name, left, right, {:sample => sample, :split_hets => true, :only_variants => (right-left>1000)}).sort{|a,b| a.variant_type <=>b.variant_type}.each do |v|  
          data << [v.variant_type.downcase,"#{v.pos}#{v.ref.ord}#{v.alt.ord}",v.pos,v.ref.length,v.ref,v.alt,v.qual]
        end
        render :json => {
          :success => true,
          :data => data
        }
      when 'describe'
        begin
          @bioentry = Bioentry.find(param['bioentry'])
          @experiment = Experiment.find(param['experiment'])
          be = @experiment.bioentries_experiments.find_by_bioentry_id(@bioentry.id)
          @variants = @experiment.find_variants(be.sequence_name,param['pos'].to_i)
          render :partial => "item"
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
    rescue => e
      logger.info "\n\nError with Variant->track_data:#{$!}#{e.backtrace.join("\n")}\n\n"
      render :json => {:success => false}
    end
  end
  
  private
  
  def get_variants
    @variant = Variant.find(params[:id])
    page = params[:page] || 1
    @bioentry = Bioentry.find(params[:bioentry_id] || @variant.bioentries_experiments.first.bioentry_id)
    be = @variant.bioentries_experiments.find_by_bioentry_id(@bioentry.id)
    @variants = @variant.get_data(be.sequence_name,0,@bioentry.length,{:only_variants => true})
    @variants = @variants.sort{|a,b| b.qual<=>a.qual}.paginate(:page => page, :per_page => 20)
  end
end
