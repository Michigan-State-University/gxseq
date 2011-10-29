class TermDbxref < ActiveRecord::Base
  set_table_name "term_dbxref"
  belongs_to :term, :class_name => "Term"
  belongs_to :dbxref, :class_name => "Dbxref"
end