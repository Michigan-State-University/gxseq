class TrackConfiguration < ActiveRecord::Base
  belongs_to :track_layout
  belongs_to :track
  belongs_to :user
  # TODO: refactor this
  def config
    " id: '#{track.id}',
      name: '#{track.name}',
      bioentry: '#{track.bioentry.id}',
      source: '#{track.source}',
      data: '#{track.data || 'false'}',
      edit: '#{track.edit || 'false'}',
      height: #{height || 50},
      single: #{track.single || 'false'},
      showControls: #{showControls || 'true'},
      showAdd: #{showAdd || 'false'},
      color_above: '#{color_above || '0'}',
      color_below: '#{color_below || '0'}',
      iconCls: '#{track.iconCls}',
      #{track.respond_to?('sample') ? "sample: '#{track.sample}'," : ""}
      #{track.respond_to?('peaks') ? "peaks: #{track.peaks}" : 'peaks: false'}
    "
  end
  
  def track_config
    self.track.custom_config+self.track.type+config
  end
  
end


# == Schema Information
#
# Table name: track_configurations
#
#  id              :integer(38)     not null, primary key
#  track_layout_id :integer(38)
#  track_id        :integer(38)
#  user_id         :integer(38)
#  name            :string(255)
#  data            :string(255)
#  edit            :string(255)
#  height          :string(255)
#  showControls    :string(255)
#  showAdd         :string(255)
#  single          :string(255)
#  creator_id      :integer(38)
#  updater_id      :integer(38)
#  created_at      :datetime
#  updated_at      :datetime
#  color_above     :string(255)
#  color_below     :string(255)
#

