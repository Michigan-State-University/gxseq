class BioentriesController < ApplicationController

  def index
    @bioentry_species = Taxon.in_use_species.includes(:scientific_name, :taxon_versions => [:taxon => [:taxon_names]])
    logger.info "\n\n#{pp @bioentry_species.all}\n\n"
  end
  
  def new
  end
  
  def create
  end
  
  def show
    @bioentry = Bioentry.find(params[:id])
    
    #possible config params
    ##the feature_id will be used to lookup the given feature on load. It will NOT set the position.
    @feature_id = params[:feature_id]
    @gene_id = params[:gene_id]
    ##position / zoom
    @position = params[:pos]
    @bases = params[:b]
    @pixels = params[:p]
    ##tracks will be activated by type or id if they are not already in the layout
    @tracks_param = params[:tracks]
    
    @add_tracks = []
    if(@tracks_param && @tracks_param.is_a?(Array))
      @tracks_param.each do |track|
        if(track.is_a?(String) && @bioentry.respond_to?(track) && @bioentry.send(track))
          @add_tracks << @bioentry.send(track).id
        elsif(track.respond_to?('to_i') && @bioentry.tracks.find(track.to_i))
          @add_tracks << @bioentry.tracks.find(track).id
        end
      end
    end
    
    #default active track
    @active_tracks = "['#{@bioentry.six_frame_track.id}','#{@bioentry.models_track.id}']"
     
    ## set layout
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
    #if we have a layout_id find the layout and set the active tracks
    if(layout_id)      
      begin
        @layout = TrackLayout.find(layout_id)
        @active_tracks = @layout.active_tracks
      rescue
        @layout = nil
      end
    end
    #if we have tracks passed on the param make sure they are active
    @add_tracks = @add_tracks.delete_if{|t|@active_tracks.match(/#{t}/)}
    unless(@add_tracks.empty?)
      @active_tracks.gsub!("]",",'#{@add_tracks.join("','")}']")
    end
    render :layout => 'sequence_viewer'
  end
end
