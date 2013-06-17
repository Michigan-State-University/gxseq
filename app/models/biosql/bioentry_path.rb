class Biosql::BioentryPath < ActiveRecord::Base
  set_table_name "bioentry_path"
  set_primary_keys :object_bioentry_id, :subject_bioentry_id, :term_id, :distance
  belongs_to :term, :class_name => "Term"
  belongs_to :object_bioentry, :class_name=>"Bioentry"
  belongs_to :subject_bioentry, :class_name=>"Bioentry"
end

# == Schema Information
#
# Table name: bioentry_path
#
#  object_bioentry_id  :integer          not null
#  subject_bioentry_id :integer          not null
#  term_id             :integer          not null
#  distance            :integer
#  created_at          :datetime
#  updated_at          :datetime
#

