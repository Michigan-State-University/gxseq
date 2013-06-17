# == Schema Information
#
# Table name: track_layouts
#
#  active_tracks :string(255)
#  assembly      :string(255)
#  assembly_id   :integer
#  bases         :string(255)
#  created_at    :datetime
#  id            :integer          not null, primary key
#  name          :string(255)
#  pixels        :string(255)
#  position      :string(255)
#  updated_at    :datetime
#  user_id       :integer
#

class TrackLayout < ActiveRecord::Base
  belongs_to :assembly
  has_many :track_configurations, :dependent => :destroy
  validates_uniqueness_of :name, :scope => [:user_id, :assembly_id], :on => :create, :message => "is already in use"
  # TODO: refactor this
end

