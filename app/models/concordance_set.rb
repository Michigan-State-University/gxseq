class ConcordanceSet < ActiveRecord::Base
  belongs_to :assembly
  has_many :concordance_items
  validates_presence_of :name
  validates_presence_of :assembly
  accepts_nested_attributes_for :concordance_items
  validates_associated :concordance_items
end