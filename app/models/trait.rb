class Trait < ActiveRecord::Base
  belongs_to :sample
  belongs_to :user
  belongs_to :term, :class_name => "Biosql::Term", :foreign_key => "term_id"
  scope :with_term, lambda {|term_id| includes(:term).where{term.term_id == my{term_id}}}
  validates_uniqueness_of :term_id, :scope => [:sample_id]
end