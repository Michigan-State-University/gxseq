class FavoriteSeqfeature < Favorite
  belongs_to :item, :class_name => 'Biosql::Feature::Seqfeature', :foreign_key => :favorite_item_id
  belongs_to :seqfeature, :class_name => 'Biosql::Feature::Seqfeature', :foreign_key => :favorite_item_id
end