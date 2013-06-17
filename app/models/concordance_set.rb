# == Schema Information
#
# Table name: concordance_sets
#
#  assembly_id :integer
#  created_at  :datetime
#  id          :integer          not null, primary key
#  name        :string(255)
#  updated_at  :datetime
#

class ConcordanceSet < ActiveRecord::Base
  belongs_to :assembly
  has_many :concordance_items
  validates_presence_of :name
  validates_presence_of :assembly
  accepts_nested_attributes_for :concordance_items
  validates_associated :concordance_items
end
