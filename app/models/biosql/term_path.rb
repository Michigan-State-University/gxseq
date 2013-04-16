class Biosql::TermPath < ActiveRecord::Base
  set_table_name "term_path"
  belongs_to :ontology, :class_name => "Ontology"
  belongs_to :subject_term, :class_name => "Term"
  belongs_to :object_term, :class_name => "Term"
  belongs_to :predicate_term, :class_name => "Term"
end