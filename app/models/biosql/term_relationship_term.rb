# == Schema Information
#
# Table name: term_relationship_term
#
#  created_at           :datetime
#  term_id              :integer          not null
#  term_relationship_id :integer          not null, primary key
#  updated_at           :datetime
#

class Biosql::TermRelationshipTerm < ActiveRecord::Base
  set_table_name "term_relationship_term"
  set_primary_key :term_relationship_id
  belongs_to :term_relationship, :class_name => "TermRelationship"
  belongs_to :term, :class_name => "Term"
end
