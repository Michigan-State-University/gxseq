class Version < ActiveRecord::Base 
  attr_accessible :item_id, :item_type, :created_at, :event, :object, :whodunnit, :parent_id, :parent_type
end