class Biosql::TaxonName < ActiveRecord::Base
  set_table_name "taxon_name"
  set_primary_keys :taxon_id, :name, :name_class
  belongs_to :taxon
  validates_uniqueness_of :name_class, :scope => :taxon_id, :if => Proc.new { |taxon_name| taxon_name.name_class == 'scientific name'}
end

# == Schema Information
#
# Table name: taxon_name
#
#  taxon_id   :integer          not null
#  name       :string(255)      not null
#  name_class :string(32)       not null
#  created_at :datetime
#  updated_at :datetime
#

