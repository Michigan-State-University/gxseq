class Trait < ActiveRecord::Base
  belongs_to :sample
  belongs_to :user
  belongs_to :term, :class_name => "Biosql::Term", :foreign_key => "term_id"
  scope :with_term, lambda {|term_id| includes(:term).where{term.term_id == my{term_id}}}
  validates_uniqueness_of :term_id, :scope => [:sample_id]
  validates_presence_of :term
  validates_presence_of :value
  
  # Virtual method to simplify key-value creation
  def key=(keyval)
    terms = Biosql::Term.sample_tags.where{upper(name)==my{keyval.upcase}}
    self.term = terms.first || build_term(:name => keyval, :ontology_id => Biosql::Term.sample_ont_id)
  end
end