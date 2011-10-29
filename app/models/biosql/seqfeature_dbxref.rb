class SeqfeatureDbxref < ActiveRecord::Base
  set_table_name "seqfeature_dbxref"
  set_primary_keys :seqfeature_id, :dbxref_id
  belongs_to :seqfeature, :class_name => "Seqfeature", :foreign_key => "seqfeature_id"
  belongs_to :dbxref, :class_name => "Dbxref", :foreign_key => "dbxref_id"
end