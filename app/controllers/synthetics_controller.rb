#TODO: Synthetics need to be re-implemented and tested
class SyntheticsController < ApplicationController
   ##ajax routes
   def render_exp_type
      @bioentries = Bioentry.find(:all, :order => "taxon_id asc, name")   
      @synthetic = Synthetic.new()
      @experiment_type = params[:experiment_type]
      @synthetic.bioentry = Bioentry.find(params[:bioentry_id])
      @types = @synthetic.bioentry.experiments.collect(&:type).uniq - ["Synthetic"]
      render :partial  => 'exp_type'
   end
   
   def render_form
      @bioentries = Bioentry.find(:all, :order => "taxon_id asc, name") 
      @synthetic = Synthetic.new()
      @experiment_type = params[:experiment_type]
      @synthetic.bioentry = Bioentry.find(params[:bioentry_id])
      @types = @synthetic.bioentry.experiments.collect(&:type).uniq - ["Synthetic"]
      @experiments = @experiment_type.constantize.find(:all, :conditions => "bioentry_id=#{@synthetic.bioentry_id}")
      render :partial => 'form'
   end
   
   ##restful routes
   def index
     unless(params[:query].blank?)
       @species = Synthetic.all(:conditions => ["upper(name) like ?", "%#{params[:query].upcase}%"]).map(&:bioentries).flatten.uniq.collect(&:taxon).uniq.collect(&:species).uniq
     else
       @species = Synthetic.all.map(&:bioentries).flatten.uniq.collect(&:taxon).uniq.collect(&:species).uniq
     end
   end
   
   def show
      # @synthetic = Synthetic.find(params[:id])
      # render :layout => 'google_js'
      @synthetic = Synthetic.find(params[:id]) 
      respond_to do |format|
        format.html {}
        format.xml { render :layout => false }
      end
   end
   
   def new
      @bioentries = Bioentry.find(:all, :order => "taxon_id asc, name")
   end
   
   def create
      # begin         
         #convert experiment ids to new components
         params[:synthetic][:a_components] = params[:a_experiments].collect!{|exp_id| AComponent.new(:experiment_id => exp_id)} unless params[:a_experiments].blank?
         params[:synthetic][:b_components] = params[:b_experiments].collect!{|exp_id| BComponent.new(:experiment_id => exp_id)} unless params[:b_experiments].blank?
            
         ActiveRecord::Base.transaction do
            @synthetic = Synthetic.new(params[:synthetic])        
            if(@synthetic.valid?)
               @synthetic.save
               flash[:notice]="New Synthetic Experiment Created Successfully"
               redirect_to :action => :index
            else
              @experiment_type = params[:experiment_type]
              @experiments = @experiment_type.constantize.find(:all, :conditions => "bioentry_id=#{params[:synthetic][:bioentry_id]}")
              #@experiments = @synthetic.bioentry.experiments.find(:conditions => "type = #{@experiment_type}")
              @types = @synthetic.bioentry.experiments.collect(&:type).uniq - ["Synthetic"]
              @bioentries = Bioentry.find(:all, :order => "taxon_id asc, name")
              render :action => :new
            end
         end
         
      # rescue         
      #          flash[:error]="Fatal error creating experiment. Please report"
      #          redirect_to :action => :index
      #       end      
   end
   
   def edit
      @synthetic = Synthetic.find(params[:id])
      @bioentries = Bioentry.find(:all, :order => "taxon_id asc, name")
      @experiment_type = @synthetic.a_components.first.experiment.class.name
      @experiments = @synthetic.bioentry.send(@experiment_type.underscore.pluralize) - [@synthetic]      
      @types = @synthetic.bioentry.experiments.collect(&:type).uniq - ["Synthetic"]
   end
   
   def update
      begin
         @synthetic = Synthetic.find(params[:id])         
         ActiveRecord::Base.transaction do         
            @synthetic.update_attributes(params[:synthetic])
            
            #Test components add error if nil
            @synthetic.errors.add(:a_components, "can't be blank") if params[:a_experiments].blank?
            @synthetic.errors.add(:b_components, "can't be blank") if params[:b_experiments].blank?
            
            if @synthetic.errors.empty?
               
               #remove old components from synthetic and add new ones
               @synthetic.components.destroy_all
               @synthetic.a_components = params[:a_experiments].collect{|exp_id| AComponent.create(:experiment_id => exp_id)}
               @synthetic.b_components = params[:b_experiments].collect{|exp_id| BComponent.create(:experiment_id => exp_id)}
               
               #doublecheck
               raise ActiveRecord::RecordInvalid if (@synthetic.a_components.empty? || @synthetic.b_components.empty?)
               
               flash[:notice]="New Synthetic Experiment #{@synthetic.name} Updated"
               redirect_to :action => :index
            else
               
               #reset instance variables
               @experiments = @synthetic.bioentry.experiments
               @bioentries = Bioentry.find(:all, :order => "taxon_id asc, name")
               render :action => :edit
            end
         end        
      rescue         
         flash[:error]="Error updating experiment."
         redirect_to :action => :index
      end
   end
   
   def destroy
      @synthetic = Synthetic.find(params[:id])
      name = @synthetic.name
      @synthetic.destroy
      flash[:notice]="Synthetic Experiment #{name} Removed"
      redirect_to :action => :index
   end
   
   
end