class TrackLayoutsController < ApplicationController

  def index    
    @track_layouts = current_user.is_admin? ?
      TrackLayout.where(:taxon_version_id  =>  params[:taxon_version_id]) :
      TrackLayout.where(:user_id  => current_user.id, :taxon_version_id => params[:taxon_version_id])
    render :json => @track_layouts.order("created_at DESC").to_json(:only => [:name,:id])
  end

  def create
    if(params[:taxon_version_id]&&params[:name]&&params[:active_tracks]&&params[:track_configurations]&&params[:location])
      configs = JSON.parse(params[:track_configurations])
      location = JSON.parse(params[:location])
      begin         
          @track_layout = current_user.track_layouts.new(
            :name => params[:name],
            :taxon_version_id => params[:taxon_version_id],
            :active_tracks => params[:active_tracks],
            :assembly => 1,
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
                :name => config['name'],
                :data => config['data'],
                :edit => config['edit'],
                :height => config['height'],
                :showControls => config['showControls'],
                :showAdd => config['showAdd'],
                :single => config['single'],
                :color_above => config['color_above'],
                :color_below => config['color_below'],
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
