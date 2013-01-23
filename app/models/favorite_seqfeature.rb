class FavoriteSeqfeature < Favorite
  belongs_to :item, :class_name => 'Seqfeature', :foreign_key => :favorite_item_id
  belongs_to :seqfeature, :foreign_key => :favorite_item_id
end