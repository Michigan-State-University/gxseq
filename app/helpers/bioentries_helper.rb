module BioentriesHelper
  # returns javascript required to insert sequence viewer onto a page
  def build_genome_gui(bioentry,all_tracks,opts={})
    view = opts[:view]||{:position => 1,:bases => 50,:pixels => 1}
    active_tracks = opts[:active]||[]
    
    # Build Track Configuration Array
    track_configs = []
    all_tracks.each do |track|
      track_config = track.get_config.merge({
        :bioentry => bioentry.id,
        :path => (current_user.try(:preferred_track_path,track) || track.folder)
      })
      if(@layout)
        # Merge saved config data
        layout_config = @layout.track_configurations.select{|tc| tc.track==track}.first.try(:track_config)
        track_config.merge!(layout_config) if layout_config
      end
      track_configs<<track_config
    end
    
    # Build the full configuration
    gui_config = {
      :tracks => track_configs,
      # Setup
      :renderTo => 'center-column',
      :active => active_tracks,
      :genome => track_sequence_metadata_url,
      :refresh_path => bioentry_url(bioentry),
      :bioentry => bioentry.id,
      :assembly_id => bioentry.assembly_id,
      :layout_path => track_layouts_path(:assembly_id => bioentry.assembly_id),
      :updateNodePath => update_track_node_user_url(current_user.try(:id)),
      # Auth data
      :root_path => root_path,
      :auth_token => form_authenticity_token,
      # Initial view
      :location => {
        :position => view[:position],
        :bases => view[:bases],
        :pixels => view[:pixels]
      },
      # Admin Contact
      :admin => {
        :name => APP_CONFIG[:admin_email],
        :email => APP_CONFIG[:admin_email],
        :notes => APP_CONFIG[:site_name]
      }
    }
    # optional configs
    gui_config[:gene_id] = @gene_id if @gene_id
    gui_config[:feature_id] = @feature_id if @feature_id
    
    # config text
    text = "<script type='text/javascript'>\n"
    text += "AnnoJ.config = #{gui_config.to_json};\n"
    
    # Run init on ready Ext event
    text += "Ext.onReady(function(){AnnoJ.init();});\n"
    text += "</script>"
    
    return text.html_safe
  end
end
