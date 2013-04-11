class Bio::TermRelationshipTerm < ActiveRecord::Base
  set_table_name "term_relationship_term"
  set_primary_key :term_relationship_id
  belongs_to :term_relationship, :class_name => "TermRelationship"
  belongs_to :term, :class_name => "Term"
end