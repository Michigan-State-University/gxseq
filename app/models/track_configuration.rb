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
  serialize :track_config, Hash
end

