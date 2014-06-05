class CombosController < ApplicationController
  ##Ajax Route
  def sample_select
    assembly = Assembly.find(params[:assembly_id])
    render :partial => 'sample_select', :locals => {
      :samples => assembly.samples,
      :combo => Combo.new,
      :concordance_sets => assembly.concordance_sets
    }
  end
  
  ##restful routes
  def index
    query = (params[:query] || '').upcase
    @combos = Combo.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @combos.map(&:assembly).map(&:species).uniq
  end

  def show
    @combo = Combo.find(params[:id])
    @bioentry = Biosql::Bioentry.find(params[:bioentry_id] || @combo.assembly.bioentries.first.id) rescue nil
  end

  def new 
    @assemblies = Assembly.includes(:taxon => :scientific_name).order("taxon_name.name").accessible_by(current_ability)
    @combo = Combo.new
    authorize! :create, @combo
  end

  def create
    #convert sample ids to new components
    params[:combo][:a_components] = params[:a_samples].collect!{|sample_id| AComponent.new(:sample_id => sample_id)} unless params[:a_samples].blank?
    params[:combo][:b_components] = params[:b_samples].collect!{|sample_id| BComponent.new(:sample_id => sample_id)} unless params[:b_samples].blank?
    ActiveRecord::Base.transaction do
      @combo = Combo.new(params[:combo])
      @combo.user = current_user
      if(@combo.valid?)
        @combo.save
        flash[:notice]="New Combo Sample Created Successfully"
        redirect_to @combo
      else
        @assemblies = Assembly.includes(:species => :scientific_name).order("taxon_name.name").accessible_by(current_ability)
        render :action => :new
      end
    end
  end

  def edit
    @combo = Combo.find(params[:id])
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def update
    begin
      @combo = Combo.find(params[:id])
      #convert sample ids to new components
      params[:combo][:a_components] = params[:a_samples].collect!{|sample_id| AComponent.new(:sample_id => sample_id)} unless params[:a_samples].blank?
      params[:combo][:b_components] = params[:b_samples].collect!{|sample_id| BComponent.new(:sample_id => sample_id)} unless params[:b_samples].blank?
      ActiveRecord::Base.transaction do
        @combo.update_attributes(params[:combo])
        if @combo.errors.empty?
          flash[:notice]="Combo Sample #{@combo.name} Updated"
          redirect_to :action => :show
        else
          @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
          render :action => :edit
        end
      end        
    rescue => e
      flash[:error]="Error updating sample."
      server_error(e,"Error")
      redirect_to :action => :index
    end
  end

  def destroy
    @combo = Combo.find(params[:id])
    name = @combo.name
    @combo.destroy
    flash[:notice]="Combo Sample #{name} Removed"
    redirect_to :action => :index
  end


end