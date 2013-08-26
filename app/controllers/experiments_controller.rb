class ExperimentsController < ApplicationController
  
  def asset_details
    begin
      if params[:exp_id] && @experiment = Experiment.find(params[:exp_id])
        if(asset = @experiment.big_wig)
          render :partial => "experiments/assets", :locals => {:experiment => @experiment}
        end
      else
        render :text => "No experiment Found!?"
      end
    rescue
      logger.info "\n\nError in experiemnt asset details #{$!}\n\n"
      render :text => "<span style='color:red;'>Error looking up experiment assets</span>"
    end
  end
end
