class TrackLayoutsController < ApplicationController

  def index
    if(current_user)
      @track_layouts = current_user.is_admin? ?
        TrackLayout.where(:assembly_id  =>  params[:assembly_id]) :
        TrackLayout.where(:user_id  => current_user.id, :assembly_id => params[:assembly_id])
      render :json => @track_layouts.order("created_at DESC").to_json(:only => [:name,:id])
    else
      render :json => []
    end
  end

  def create
    if(params[:assembly_id]&&params[:name]&&params[:active_tracks]&&params[:track_configurations]&&params[:location])
      configs = JSON.parse(params[:track_configurations])
      location = JSON.parse(params[:location])
      begin         
        @track_layout = current_user.track_layouts.new(
          :name => params[:name],
          :assembly_id => params[:assembly_id],
          :active_tracks => params[:active_tracks],
          :position => location['position'],
          :bases => location['bases'],
          :pixels => location['pixels']
        )
        ActiveRecord::Base.transaction do
          if(@track_layout.valid?)
            @track_layout.save!
            configs.each do |config|
              tc = @track_layout.track_configurations.create(
                :user => current_user,
                :track_id => config['id'],
                :track_config => config
              )
            end
            render :json => 
            {
              :success => true
            }
          else
            render :json  => {
              :success => false,
              :message => "Layout name must be unique"
            }
          end
          
        end
      rescue
        logger.info "\n\n#{$!}\n#{caller.join("\n")}\n\n"
        render :json  => {
          :success => false,
          :messsage => "Error Creating Layout"
        }
      end
    else
      render :json  => {
        :success => false,
        :message => "Missing parameter"
      }
    end
  end

end
