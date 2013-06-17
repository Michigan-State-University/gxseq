class Biosql::BioentryQualifierValue < ActiveRecord::Base
  set_table_name "bioentry_qualifier_value"
  set_primary_keys :bioentry_id, :term_id, :rank
  belongs_to :bioentry, :class_name => "Bioentry"
  belongs_to :term, :class_name => "Term"
  
  def name
    term.name
  end
  
  def to_s
    value
  end
  
end

# == Schema Information
#
# Table name: bioentry_qualifier_value
#
#  bioentry_id :integer          not null
#  term_id     :integer          not null
#  value       :string(4000)
#  rank        :integer          default(0), not null
#  created_at  :datetime
#  updated_at  :datetime
#

