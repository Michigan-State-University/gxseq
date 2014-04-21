class SamplesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  # Used by smoothing tool
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
  
  # only responds to json api
  # vulnerable to csrf!
  def create
    if request.format.json? 
      @sample = Sample.new(params[:sample])
      authorize! :api_create, @sample
      # Assign owner
      @sample.user = current_user
      # Auto assign concordance
      @sample.concordance_set_id ||= @sample.assembly.try(:concordance_sets).try(:first).try(:id)
      begin
        respond_to do |format|
          if @sample.save
            format.json { render json: @sample, :status => :created, location: @sample }
          else
            format.json { render json: @sample.errors, :status => :invalid }
          end
        end
      rescue => e
        server_error(e,"Sample Create Error; #{$!}")
        render json: {:error => "#{$!}"}, :status => :error
      end
    else
      render json: {:error => "Invalid Request Format"}, :status => :error
    end
  end
  
end
# 
# {
#   'sample' : {
#     'type': 'RnaSeq',
#     'assembly_id': 10320,
#     'group_id': 10100,
#     'name': 'Sample123',
#     'description': 'blahblahblah',
#     'traits_attributes': [
#       {'key': 'Trait1', 'value': 'asdf'},
#       {'key': 'Trait2', 'value': 'asdf'},
#     ],
#     'assets_attributes': [
#       {'type': 'Bam', 'local_path': '/path/to/data'},
#       {'type': 'BigWig', 'local_path': '/path/to/data'}
#     ]
#   }
# }