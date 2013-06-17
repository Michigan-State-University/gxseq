# == Schema Information
#
# Table name: reference
#
#  authors      :string(4000)
#  crc          :string(32)
#  created_at   :datetime
#  dbxref_id    :integer
#  location     :string(4000)     not null
#  reference_id :integer          not null, primary key
#  title        :string(4000)
#  updated_at   :datetime
#

class Biosql::Reference < ActiveRecord::Base
  set_table_name "reference"
  set_primary_key :reference_id
  belongs_to :dbxref, :class_name => "Dbxref"
  has_many :bioentry_references, :class_name=>"BioentryReference"
  has_many :bioentries, :through=>:bioentry_references
end
