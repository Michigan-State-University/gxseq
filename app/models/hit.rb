class Hit < ActiveRecord::Base
  belongs_to :blast_iteration, :inverse_of => :hits
  has_many :hsps, :inverse_of => :hit, :dependent => :delete_all
  has_one :best_hsp_with_scores, :class_name => "Hsp", :order => "hsps.bit_score DESC", :select => [:id,:hit_id,:bit_score,:score,:evalue]
  
  validates_presence_of :blast_iteration_id
  # accepts_nested_attributes_for :hsps
end