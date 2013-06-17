class Biosql::SeqfeatureDbxref < ActiveRecord::Base
  set_table_name "seqfeature_dbxref"
  set_primary_keys :seqfeature_id, :dbxref_id
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature", :foreign_key => "seqfeature_id"
  belongs_to :dbxref, :class_name => "Dbxref", :foreign_key => "dbxref_id"
end

# == Schema Information
#
# Table name: seqfeature_dbxref
#
#  seqfeature_id :integer          not null
#  dbxref_id     :integer          not null
#  rank          :integer
#  created_at    :datetime
#  updated_at    :datetime
#

