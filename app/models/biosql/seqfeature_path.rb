class Biosql::SeqfeaturePath < ActiveRecord::Base
  set_table_name "seqfeature_path"
  set_primary_keys :object_seqfeature_id, :subject_seqfeature_id, :term_id
  belongs_to :object_seqfeature, :class_name => "Seqfeature", :foreign_key => "object_seqfeature_id"
  belongs_to :subject_seqfeature, :class_name => "Seqfeature", :foreign_key => "subject_seqfeature_id"
  belongs_to :term, :class_name => "Term"
end

# == Schema Information
#
# Table name: seqfeature_path
#
#  object_seqfeature_id  :integer          not null
#  subject_seqfeature_id :integer          not null
#  term_id               :integer          not null
#  distance              :integer
#  created_at            :datetime
#  updated_at            :datetime
#

