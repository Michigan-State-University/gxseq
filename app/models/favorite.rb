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

class Favorite < ActiveRecord::Base
  belongs_to :user
  
end
