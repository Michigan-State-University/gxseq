# == Schema Information
#
# Table name: bioentry_relationship
#
#  bioentry_relationship_id :integer          not null, primary key
#  created_at               :datetime
#  object_bioentry_id       :integer          not null
#  rank                     :integer
#  subject_bioentry_id      :integer          not null
#  term_id                  :integer          not null
#  updated_at               :datetime
#

class Biosql::BioentryRelationship < ActiveRecord::Base
  set_table_name "bioentry_relationship"
  set_primary_key "bioentry_relationship_id"
  belongs_to :object_bioentry, :class_name => "Bioentry"
  belongs_to :subject_bioentry, :class_name => "Bioentry"
  belongs_to :term
end
