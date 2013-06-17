# == Schema Information
#
# Table name: location_qualifier_value
#
#  created_at  :datetime
#  int_value   :integer
#  location_id :integer          not null
#  term_id     :integer          not null
#  updated_at  :datetime
#  value       :string(255)      not null
#

class Biosql::LocationQualifierValue < ActiveRecord::Base
  set_table_name "location_qualifier_value"
  belongs_to :location, :class_name => "Location"
  belongs_to :term, :class_name => "Term"
end
