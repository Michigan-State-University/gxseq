class Bio::BioentryDbxref < ActiveRecord::Base
  set_table_name "bioentry_dbxref"
  set_primary_keys :dbxref_id, :bioentry_id
  belongs_to :bioentry, :class_name => "Bioentry"
  belongs_to :dbxref, :class_name => "Dbxref"
end