class Hsp < ActiveRecord::Base
  belongs_to :hit, :inverse_of => :hsps
  
  validates_presence_of :hit
end