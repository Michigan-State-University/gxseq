class TaxonName < ActiveRecord::Base
  set_table_name "taxon_name"
  set_primary_keys :taxon_id, :name, :name_class
  belongs_to :taxon, :class_name => "Taxon"
  validates_uniqueness_of :name_class, :scope => :taxon_id, :if => Proc.new { |taxon_name| taxon_name.name_class == 'scientific name'}
end


# == Schema Information
#
# Table name: sg_taxon_name
#
#  tax_oid    :integer(38)     not null
#  name       :string(128)     not null
#  name_class :string(32)      not null
#

