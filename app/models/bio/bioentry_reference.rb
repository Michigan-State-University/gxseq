class Bio::BioentryReference < ActiveRecord::Base
  set_table_name "bioentry_reference"
  set_primary_keys :bioentry_id, :reference_id, :rank
  belongs_to :bioentry, :class_name => "Bioentry"
  belongs_to :reference , :class_name => "Reference"
end