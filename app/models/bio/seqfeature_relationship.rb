class Bio::Feature::SeqfeatureRelationship < ActiveRecord::Base
  set_table_name "seqfeature_relationship"
  set_primary_key "seqfeature_relationship_id"
  belongs_to :term, :class_name => "Term"
  belongs_to :object_seqfeature, :class_name => "Seqfeature"
  belongs_to :subject_seqfeature, :class_name => "Seqfeature"
end