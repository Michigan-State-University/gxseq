class Biosql::Reference < ActiveRecord::Base
  set_table_name "reference"
  set_primary_key :reference_id
  belongs_to :dbxref, :class_name => "Dbxref"
  has_many :bioentry_references, :class_name=>"BioentryReference"
  has_many :bioentries, :through=>:bioentry_references
end

# == Schema Information
#
# Table name: sg_reference
#
#  oid      :integer(38)     not null, primary key
#  title    :string(1000)
#  authors  :string(4000)    not null
#  location :string(512)     not null
#  crc      :string(32)
#  dbx_oid  :integer(38)
#

