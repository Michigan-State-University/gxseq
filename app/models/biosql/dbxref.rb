class Dbxref < ActiveRecord::Base
  set_table_name "dbxref"
  set_primary_key :dbxref_id
  has_many :dbxref_qualifier_values, :class_name => "DbxrefQualifierValue"
  has_many :locations, :class_name => "Location"
  has_many :references, :class_name=>"Reference"
  has_many :term_dbxrefs, :class_name => "TermDbxref"
  has_many :bioentry_dbxrefs, :class_name => "BioentryDbxref"
end

# == Schema Information
#
# Table name: sg_dbxref
#
#  oid       :integer(38)     not null, primary key
#  dbname    :string(32)      not null
#  accession :string(64)      not null
#  version   :integer(2)      default(0), not null
#

