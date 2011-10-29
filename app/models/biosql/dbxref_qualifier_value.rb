class DbxrefQualifierValue < ActiveRecord::Base
  set_table_name "dbxref_qualifier_value"
  set_primary_keys :dbxref_id, :term_id, :rank
  belongs_to :dbxref, :class_name => "Dbxref"
  belongs_to :term, :class_name => "Term"
end