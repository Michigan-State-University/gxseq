class SamplesController < ApplicationController
  
  def asset_details
    begin
      if params[:sample_id] && @sample = Sample.find(params[:sample_id])
        if(asset = @sample.big_wig)
          render :partial => "samples/assets", :locals => {:sample => @sample}
        end
      else
        render :text => "No sample Found!?"
      end
    rescue
      logger.info "\n\nError in sample asset details #{$!}\n\n"
      render :text => "<span style='color:red;'>Error looking up sample assets</span>"
    end
  end
end
