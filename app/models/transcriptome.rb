# == Schema Information
#
# Table name: assemblies
#
#  created_at :datetime
#  group_id   :integer
#  id         :integer          not null, primary key
#  species_id :integer
#  taxon_id   :integer
#  type       :string(255)
#  updated_at :datetime
#  version    :string(255)
#

class Transcriptome < Assembly
  # default track setup for sequence view
  def default_tracks
    [six_frame_track.try(:id),generic_feature_tracks.first.try(:id)]
  end
end
