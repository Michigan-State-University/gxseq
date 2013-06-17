# == Schema Information
#
# Table name: term_relationship
#
#  created_at           :datetime
#  object_term_id       :integer          not null
#  ontology_id          :integer          not null
#  predicate_term_id    :integer          not null
#  subject_term_id      :integer          not null
#  term_relationship_id :integer          not null
#  updated_at           :datetime
#

class Biosql::TermRelationship < ActiveRecord::Base
  set_table_name "term_relationship"
end
