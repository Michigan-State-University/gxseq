class Biosql::BioentryDbxref < ActiveRecord::Base
  set_table_name "bioentry_dbxref"
  set_primary_keys :dbxref_id, :bioentry_id
  belongs_to :bioentry, :class_name => "Bioentry"
  belongs_to :dbxref, :class_name => "Dbxref"
end

# == Schema Information
#
# Table name: bioentry_dbxref
#
#  bioentry_id :integer          not null
#  dbxref_id   :integer          not null
#  rank        :integer
#  created_at  :datetime
#  updated_at  :datetime
#

