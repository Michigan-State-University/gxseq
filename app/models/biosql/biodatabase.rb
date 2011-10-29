class Biodatabase < ActiveRecord::Base
  set_table_name "biodatabase"
  set_primary_key :biodatabase_id
  has_many :bioentries, :class_name =>"Bioentry", :foreign_key => "biodatabase_id"
end



# == Schema Information
#
# Table name: sg_biodatabase
#
#  oid         :integer(38)     not null, primary key
#  name        :string(32)      not null
#  authority   :string(32)
#  description :string(256)
#  acronym     :string(12)
#  uri         :string(128)
#  deleted_at  :datetime
#  updated_at  :datetime
#

