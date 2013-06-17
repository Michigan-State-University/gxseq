# == Schema Information
#
# Table name: seqfeature_relationship
#
#  created_at                 :datetime
#  object_seqfeature_id       :integer          not null
#  rank                       :integer
#  seqfeature_relationship_id :integer          not null, primary key
#  subject_seqfeature_id      :integer          not null
#  term_id                    :integer          not null
#  updated_at                 :datetime
#

class Biosql::SeqfeatureRelationship < ActiveRecord::Base
  set_table_name "seqfeature_relationship"
  set_primary_key "seqfeature_relationship_id"
  belongs_to :term, :class_name => "Term"
  belongs_to :object_seqfeature, :class_name => "Seqfeature"
  belongs_to :subject_seqfeature, :class_name => "Seqfeature"
end
