class TrackLayout < ActiveRecord::Base
  belongs_to :taxon_version
  has_many :track_configurations, :dependent => :destroy
  validates_uniqueness_of :name, :scope => [:user_id, :taxon_version_id], :on => :create, :message => "is already in use"
  # TODO: refactor this
end


# == Schema Information
#
# Table name: track_layouts
#
#  id            :integer(38)     not null, primary key
#  bioentry_id   :integer(38)
#  user_id       :integer(38)
#  name          :string(255)
#  assembly      :string(255)
#  position      :string(255)
#  bases         :string(255)
#  pixels        :string(255)
#  active_tracks :string(255)
#  creator_id    :integer(38)
#  updater_id    :integer(38)
#  created_at    :datetime
#  updated_at    :datetime
#

