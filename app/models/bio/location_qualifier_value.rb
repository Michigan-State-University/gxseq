class Bio::LocationQualifierValue < ActiveRecord::Base
  set_table_name "location_qualifier_value"
  belongs_to :location, :class_name => "Location"
  belongs_to :term, :class_name => "Term"
end