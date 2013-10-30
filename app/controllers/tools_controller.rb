class ToolsController < ApplicationController
  def smooth
    @samples = ChipChip.accessible_by(current_ability).order(:created_at)    
    #create a new smoothed dataset from the supplied sample.
    if(request.post?)
      begin
        @original=Sample.find(params[:sample_id])
        # just to test validity
        @new_sample = @original.clone({:name => params[:name], :description => params[:description]})
        if(@new_sample.valid?)
          @original.delay.create_smoothed_sample( {:name => params[:name], :description => params[:description]}, # pass the sample options again (for use in backgorund job)
            {:window => params[:window].to_i,:type => params[:type],:cutoff => params[:cutoff]}
          )
          flash[:notice] = "The Smoothing Job has been submitted. When it is complete #{params[:name]} will be listed with the other #{@original.class} samples"
          redirect_to :action => :index
        else
          render :action => "smooth"
        end
      rescue
        logger.info "\n\nError Smoothing dataset: #{$!}\n\n"
        flash[:error] = "Could not create new sample"
        redirect_to :action => "smooth"
      end
    else      
      #render the form
    end
  end
  
  def details
  end
end
