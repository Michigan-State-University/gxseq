# == Schema Information
#
# Table name: term_synonym
#
#  created_at  :datetime
#  ora_synonym :string(255)      not null
#  term_id     :integer          not null
#  updated_at  :datetime
#

class Biosql::TermSynonym < ActiveRecord::Base
  set_table_name "term_synonym"
  belongs_to :term, :class_name => "Term"
end
