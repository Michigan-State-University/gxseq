class Biosql::DbxrefQualifierValue < ActiveRecord::Base
  set_table_name "dbxref_qualifier_value"
  set_primary_keys :dbxref_id, :term_id, :rank
  belongs_to :dbxref, :class_name => "Dbxref"
  belongs_to :term, :class_name => "Term"
end

# == Schema Information
#
# Table name: dbxref_qualifier_value
#
#  dbxref_id  :integer          not null
#  term_id    :integer          not null
#  rank       :integer          default(0), not null
#  value      :string(4000)
#  created_at :datetime
#  updated_at :datetime
#

