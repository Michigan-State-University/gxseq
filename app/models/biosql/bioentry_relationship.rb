class BioentryRelationship < ActiveRecord::Base
  set_table_name "bioentry_relationship"
  set_primary_key "bioentry_relationship_id"
  belongs_to :object_bioentry, :class_name => "Bioentry"
  belongs_to :subject_bioentry, :class_name => "Bioentry"
  belongs_to :term
end