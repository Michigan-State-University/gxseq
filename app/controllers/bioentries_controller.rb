class BioentriesController < ApplicationController

  def index
    @bioentry_species = Taxon.in_use_species.includes(:scientific_name, :taxon_versions => [:taxon => [:taxon_names]])
    respond_to do |wants|
      wants.html {}
    end
  end
  
  def new
  end
  
  def create
  end
  
  def show
    @bioentry = Bioentry.find(params[:id])
    
    # config params
    # the feature_id will be used to lookup the given feature on load. It will NOT set the position.
    @feature_id = params[:feature_id]
    @gene_id = params[:gene_id]
    # position
    @position = params[:pos]
    # zoom
    @bases = params[:b]
    @pixels = params[:p]
    # tracks will be activated by type or id if no layout is provided
    @tracks_param = params[:tracks]
    
    ## get layout id
    if(params[:default])
      current_user.preferred_track_layout=nil, @bioentry
      current_user.save!
      layout_id = nil
    elsif params[:layout_id]
      layout_id = params[:layout_id]
      current_user.preferred_track_layout=layout_id, @bioentry
      current_user.save! 
    else
      layout_id = current_user.preferred_track_layout(@bioentry)
    end
    
    # if we have a layout_id find the layout and set the active tracks
    # otherwise check the parameters for track ids
    # fallback on default tracks
    if(layout_id)
      begin
        @layout = TrackLayout.find(layout_id)
        @active_tracks = @layout.active_tracks
      rescue
        @layout = nil
      end
    else
      @param_track_ids = []
      if(@tracks_param && @tracks_param.is_a?(Array))
        @tracks_param.each do |track|
          if(track.is_a?(String) && @bioentry.respond_to?(track) && @bioentry.send(track))
            @param_track_ids << @bioentry.send(track).id
          elsif(track.respond_to?('to_i') && @bioentry.tracks.find(track.to_i))
            @param_track_ids << @bioentry.tracks.find(track).id
          end
        end
      end
      unless(@param_track_ids.empty?)
        # use parameter tracks
        @active_tracks = @param_track_ids.to_json
      else
        # use default
        @active_tracks =[@bioentry.six_frame_track.id,@bioentry.models_track.id].to_json
      end
    end
    render :layout => 'sequence_viewer'
  end
  
  def edit
    @bioentry = Bioentry.find(params[:id])
  end

  def update
    @bioentry = Bioentry.find(params[:id])
    respond_to do |wants|
      if @bioentry.update_attributes(params[:bioentry])
        flash[:notice] = 'Bioentry was successfully updated.'
        wants.html { redirect_to(@bioentry) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end
  
end
