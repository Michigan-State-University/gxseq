# == Schema Information
#
# Table name: favorites
#
#  created_at       :datetime
#  favorite_item_id :integer
#  id               :integer          not null, primary key
#  type             :string(255)
#  updated_at       :datetime
#  user_id          :integer
#

class FavoriteSeqfeature < Favorite
  belongs_to :item, :class_name => 'Biosql::Feature::Seqfeature', :foreign_key => :favorite_item_id
  belongs_to :seqfeature, :class_name => 'Biosql::Feature::Seqfeature', :foreign_key => :favorite_item_id
end
