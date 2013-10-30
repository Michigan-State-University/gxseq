#TODO: Synthetics need to be re-implemented and tested
class SyntheticsController < ApplicationController
   ##ajax routes
   def render_sample_type
      @bioentries = Biosql::Bioentry.find(:all, :order => "taxon_id asc, name")   
      @synthetic = Synthetic.new()
      @sample_type = params[:sample_type]
      @synthetic.bioentry = Biosql::Bioentry.find(params[:bioentry_id])
      @types = @synthetic.bioentry.samples.collect(&:type).uniq - ["Synthetic"]
      render :partial  => 'sample_type'
   end
   
   def render_form
      @bioentries = Biosql::Bioentry.find(:all, :order => "taxon_id asc, name") 
      @synthetic = Synthetic.new()
      @sample_type = params[:sample_type]
      @synthetic.bioentry = Biosql::Bioentry.find(params[:bioentry_id])
      @types = @synthetic.bioentry.samples.collect(&:type).uniq - ["Synthetic"]
      @samples = @sample_type.constantize.find(:all, :conditions => "bioentry_id=#{@synthetic.bioentry_id}")
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
      @bioentries = Biosql::Bioentry.find(:all, :order => "taxon_id asc, name")
   end
   
   def create
      # begin         
         #convert sample ids to new components
         params[:synthetic][:a_components] = params[:a_samples].collect!{|sample_id| AComponent.new(:sample_id => sample_id)} unless params[:a_samples].blank?
         params[:synthetic][:b_components] = params[:b_samples].collect!{|sample_id| BComponent.new(:sample_id => sample_id)} unless params[:b_samples].blank?
            
         ActiveRecord::Base.transaction do
            @synthetic = Synthetic.new(params[:synthetic])        
            if(@synthetic.valid?)
               @synthetic.save
               flash[:notice]="New Synthetic Sample Created Successfully"
               redirect_to :action => :index
            else
              @sample_type = params[:sample_type]
              @samples = @sample_type.constantize.find(:all, :conditions => "bioentry_id=#{params[:synthetic][:bioentry_id]}")
              #@samples = @synthetic.bioentry.samples.find(:conditions => "type = #{@sample_type}")
              @types = @synthetic.bioentry.samples.collect(&:type).uniq - ["Synthetic"]
              @bioentries = Biosql::Bioentry.find(:all, :order => "taxon_id asc, name")
              render :action => :new
            end
         end
         
      # rescue         
      #          flash[:error]="Fatal error creating sample. Please report"
      #          redirect_to :action => :index
      #       end      
   end
   
   def edit
      @synthetic = Synthetic.find(params[:id])
      @bioentries = Biosql::Bioentry.find(:all, :order => "taxon_id asc, name")
      @sample_type = @synthetic.a_components.first.sample.class.name
      @samples = @synthetic.bioentry.send(@sample_type.underscore.pluralize) - [@synthetic]      
      @types = @synthetic.bioentry.samples.collect(&:type).uniq - ["Synthetic"]
   end
   
   def update
      begin
         @synthetic = Synthetic.find(params[:id])         
         ActiveRecord::Base.transaction do         
            @synthetic.update_attributes(params[:synthetic])
            
            #Test components add error if nil
            @synthetic.errors.add(:a_components, "can't be blank") if params[:a_samples].blank?
            @synthetic.errors.add(:b_components, "can't be blank") if params[:b_samples].blank?
            
            if @synthetic.errors.empty?
               
               #remove old components from synthetic and add new ones
               @synthetic.components.destroy_all
               @synthetic.a_components = params[:a_samples].collect{|sample_id| AComponent.create(:sample_id => sample_id)}
               @synthetic.b_components = params[:b_samples].collect{|sample_id| BComponent.create(:sample_id => sample_id)}
               
               #doublecheck
               raise ActiveRecord::RecordInvalid if (@synthetic.a_components.empty? || @synthetic.b_components.empty?)
               
               flash[:notice]="New Synthetic Sample #{@synthetic.name} Updated"
               redirect_to :action => :index
            else
               
               #reset instance variables
               @samples = @synthetic.bioentry.samples
               @bioentries = Biosql::Bioentry.find(:all, :order => "taxon_id asc, name")
               render :action => :edit
            end
         end        
      rescue         
         flash[:error]="Error updating sample."
         redirect_to :action => :index
      end
   end
   
   def destroy
      @synthetic = Synthetic.find(params[:id])
      name = @synthetic.name
      @synthetic.destroy
      flash[:notice]="Synthetic Sample #{name} Removed"
      redirect_to :action => :index
   end
   
   
end