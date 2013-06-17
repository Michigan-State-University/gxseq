# == Schema Information
#
# Table name: term_dbxref
#
#  created_at :datetime
#  dbxref_id  :integer          not null
#  rank       :integer
#  term_id    :integer          not null
#  updated_at :datetime
#

class Biosql::TermDbxref < ActiveRecord::Base
  set_table_name "term_dbxref"
  belongs_to :term, :class_name => "Term"
  belongs_to :dbxref, :class_name => "Dbxref"
end
