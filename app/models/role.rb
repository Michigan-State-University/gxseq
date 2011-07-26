class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  validates_presence_of :name
  validates_uniqueness_of :name  
  default_scope :order => 'name'
end
