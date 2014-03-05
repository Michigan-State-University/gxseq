class VariantsController < ApplicationController
  require 'will_paginate/array'
  load_and_authorize_resource
  before_filter :get_variants, :only => [:show]
  
  ##custom actions - rjs
  def initialize_sample
    @variant = Variant.find(params[:id])
    @variant.initialize_sample
    render :update do |page|
      page.replace_html 'initialize_sample', "Job Started. Refresh to view updates in the console."
    end
  end
  
  def index
    query = (params[:query] || '').upcase
    @variants = Variant.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @variants.map(&:assembly).map(&:species).uniq
  end

  def new
    @variant.assets.build
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def create
    @variant.user = current_user
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    begin
      if @variant.valid?
        @variant.save
        flash[:notice]="Sample created succesfully"
        redirect_to :action => :index
      else
        render :action => :new
      end
    rescue
      logger.info "\n\nRescued from Variant #{$!}\n\n"
      flash[:error]="Could not create sample"
      redirect_to :action => :index
    end
  end

  def show
  end

  def edit
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def update
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
    if @variant.update_attributes(params[:variant])
      flash[:notice] = 'Variant was successfully updated.'
      redirect_to(@variant)
    else
      render :action => "edit"
    end
  end

  def destroy
    @variant.destroy
    flash[:warning]="Sample #{@variant.name} has been removed"
    redirect_to :action => :index
  end
  
  private
  
  def get_variants
    page = params[:page] || 1
    @bioentry = Biosql::Bioentry.find((params[:bioentry_id] || @variant.assembly.bioentries.first.id)) rescue nil
    if(@bioentry)
      c_item = @variant.concordance_items.find_by_bioentry_id(@bioentry.id)
      @sequence_name = c_item.reference_name
      @variants = []
      @limit = 100000
      begin
        @variants = @variant.get_data(@sequence_name,0,@bioentry.length,{:only_variants => true, :limit => @limit})
      rescue => e
        logger.info "\n\n#{$!}\n\n#{e.backtrace}"
      end
    end
    @variants ||=[]
    @variants = @variants.sort{|a,b| b[:qual]<=>a[:qual]}.paginate(:page => page, :per_page => 50)
  end
end
