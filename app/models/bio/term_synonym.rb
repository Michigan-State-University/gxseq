class Bio::TermSynonym < ActiveRecord::Base
  set_table_name "term_synonym"
  belongs_to :term, :class_name => "Term"
end