module BioentriesHelper
  
  ## Work in progress
  ##TODO: Need to clean up the storage of this data
  ##TODO: Need to trim down to basic init configuration only 
  ##TODO: All other data should be requested by the js app
  def build_genome_gui(bioentry,all_tracks,opts={})
    text = "<script type='text/javascript'>\nAnnoJ.config = {\ntracks : ["
    view = opts[:view]||{:position => 1,:bases => 50,:pixels => 1}
    active_tracks = opts[:active]||[]
    #saved custom configs
    if(@layout)
      #remove any tracks that have a custom config from the list
      all_tracks -= @layout.track_configurations.collect{|tc|tc.track}
      
      @layout.track_configurations.each do |config|
        text+="
        {bioentry: '#{bioentry.id}',\n path: '#{current_user.preferred_track_path(config.track) || config.track.path}',\n#{config.track_config}},\n"
      end
    end
    
    #display all of the leftover tracks
    all_tracks.each do |track|
      text +="
      {bioentry: '#{bioentry.id}',\npath:'#{current_user.preferred_track_path(track) || track.path}',\n#{track.config}},\n"
    end
    
    text += "],\n"
    text += "renderTo : 'center-column',\n"
    text += "active : #{@active_track_string||active_tracks.to_json},\n"
    text += "genome :  '#{root_path}bioentries/metadata',\n"
    text += "refresh_path : '#{bioentry_url(bioentry)}',"
		text += "bioentry  :  '#{bioentry.id}',\n"
		text += "taxon_version_id : '#{bioentry.taxon_version_id}',\n"
		text += "gene_id : '#{@gene_id}',\n" if(@gene_id)
		text += "feature_id : '#{@feature_id}',\n" if(@feature_id)
		text += "layouts_path : '#{track_layouts_path(:taxon_version_id => bioentry.taxon_version_id)}',"
		text += "updateNodePath: '#{update_track_node_user_url}',\n"
		
		#initial view
		text += "location : {
      position : #{view[:position]},
      bases    : #{view[:bases]},
      pixels   : #{view[:pixels]}
    },\n"
    # Admin Contact
    text += "admin : {
      name  : 'Nick Thrower',
      email : 'throwern@msu.edu',
      notes : 'GLBRC IIT'
    },\n"
    # Auth data
    text += "root_path : '#{root_path}',"
    text += "auth_token : '#{form_authenticity_token}',"
    text += "};\n"
    # init on ready event
    text += "Ext.onReady(function(){AnnoJ.init();});\n"
    text += "</script>"
    return text.html_safe
  end
end
