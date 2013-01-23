module BioentriesHelper
  
  ## Work in progress
  ##TODO: Need to clean up the storage of this data
  ##TODO: Need to trim down to basic init configuration only 
  ##TODO: All other data should be requested by the js app
  
  def build_genome_gui(bioentry)
    text = "<script type='text/javascript'>\nAnnoJ.config = {\ntracks : ["
    
    #grab all of the tracks for the genome
    all_tracks = bioentry.tracks
    
    #saved custom configs
    if(@layout)
      #remove any tracks that have a custom config from the list
      all_tracks -= @layout.track_configurations.collect{|tc|tc.track}
      
      @layout.track_configurations.each do |config|
        text+="
        {#{config.track_config},\n path: '#{current_user.preferred_track_path(config.track) || config.track.path}'},\n"
      end
    end
    
    #display all of the leftover tracks
    all_tracks.each do |track|
      text +="
      {#{track.config},\npath:'#{current_user.preferred_track_path(track) || track.path}'},\n"
    end
    
    text += "],\n"
    text += "renderTo : 'center-column',\n"
    text += "active : #{@active_tracks},\n"
    text += "genome :  '#{root_path}bioentries/metadata',\n"
		text += "bioentry  :  '#{@bioentry.id}',\n"
		text += "gene_id : '#{@gene_id}',\n" if(@gene_id)
		text += "feature_id : '#{@feature_id}',\n" if(@feature_id)
		text += "updateNodePath: '#{update_track_node_user_url}',\n"
		#saved position
    if(@layout)
          text += "location : {
            assembly : '0',
            position : #{@position ? @position : @layout.position},
            bases    : #{@bases ? @bases : @layout.bases},
            pixels   : #{@pixels ? @pixels : @layout.pixels}
          },\n"
    else
  		text += "location : {
        assembly : '0',
        position : #{@position ? @position : '1'},
        bases    : #{@bases ? @bases : '50'},
        pixels   : #{@pixels ? @pixels : '1'}
      },\n"      
    end
    text += "admin : {
      name  : 'Nick Thrower',
      email : 'throwern@msu.edu',
      notes : 'GLBRC IIT'
    },\n"
    text += "root_path : '#{root_path}',"
    text += "auth_token : '#{form_authenticity_token}',"
    text += "layout_path : '#{root_path}track_layouts'"
    text += "};\n"
    text += "Ext.onReady(function(){AnnoJ.init();});\n"
    text += "</script>"
    logger.info "\n\n#{text}\n\n"
    return text.html_safe
  end
end
