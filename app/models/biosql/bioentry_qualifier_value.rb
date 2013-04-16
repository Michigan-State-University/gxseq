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