# == Schema Information
#
# Table name: components
#
#  created_at              :datetime
#  sample_id           :integer
#  id                      :integer          not null, primary key
#  combo_sample_id :integer
#  type                    :string(255)
#  updated_at              :datetime
#

class BComponent < Component
end

