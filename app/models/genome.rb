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

class Genome < Assembly
  def default_feature_definition
    'description'
  end
end
