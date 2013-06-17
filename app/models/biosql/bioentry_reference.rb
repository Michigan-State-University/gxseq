class Biosql::BioentryReference < ActiveRecord::Base
  set_table_name "bioentry_reference"
  set_primary_keys :bioentry_id, :reference_id, :rank
  belongs_to :bioentry, :class_name => "Bioentry"
  belongs_to :reference , :class_name => "Reference"
end

# == Schema Information
#
# Table name: bioentry_reference
#
#  bioentry_id  :integer          not null
#  reference_id :integer          not null
#  start_pos    :integer
#  end_pos      :integer
#  rank         :integer          default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#

