# == Schema Information
#
# Table name: term_path
#
#  created_at        :datetime
#  distance          :integer
#  object_term_id    :integer          not null
#  ontology_id       :integer          not null
#  predicate_term_id :integer          not null
#  subject_term_id   :integer          not null
#  term_path_id      :integer          not null
#  updated_at        :datetime
#

class Biosql::TermPath < ActiveRecord::Base
  set_table_name "term_path"
  belongs_to :ontology, :class_name => "Ontology"
  belongs_to :subject_term, :class_name => "Term"
  belongs_to :object_term, :class_name => "Term"
  belongs_to :predicate_term, :class_name => "Term"
end
