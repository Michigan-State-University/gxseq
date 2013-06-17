# == Schema Information
#
# Table name: seqfeature
#
#  bioentry_id    :integer          not null
#  created_at     :datetime
#  display_name   :string(64)
#  rank           :integer          default(0), not null
#  seqfeature_id  :integer          not null, primary key
#  source_term_id :integer          not null
#  type_term_id   :integer          not null
#  updated_at     :datetime
#

class Biosql::Feature::Trna < Biosql::Feature::Seqfeature
  def name
    "tRNA"
  end
end
