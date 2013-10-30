# == Schema Information
#
# Table name: track_configurations
#
#  color_above     :string(255)
#  color_below     :string(255)
#  created_at      :datetime
#  data            :string(255)
#  edit            :string(255)
#  height          :string(255)
#  id              :integer          not null, primary key
#  name            :string(255)
#  showAdd         :string(255)
#  showControls    :string(255)
#  single          :string(255)
#  track_id        :integer
#  track_layout_id :integer
#  updated_at      :datetime
#  user_id         :integer
#

class TrackConfiguration < ActiveRecord::Base
  belongs_to :track_layout
  belongs_to :track
  belongs_to :user
  # TODO: refactor this
  def config
    " id: '#{track.id}',
      name: '#{track.name}',
      source: '#{track.source_term_id}',
      data: '#{data || 'false'}',
      edit: '#{edit || 'false'}',
      height: #{height || 50},
      single: #{single || 'false'},
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

