# == Schema Information
#
# Table name: biodatabase
#
#  authority      :string(128)
#  biodatabase_id :integer          not null, primary key
#  created_at     :datetime
#  description    :string(4000)
#  name           :string(128)      not null
#  updated_at     :datetime
#

class Biosql::Biodatabase < ActiveRecord::Base
  set_table_name "biodatabase"
  set_primary_key :biodatabase_id
  has_and_belongs_to_many :taxons
  has_many :bioentries, :class_name =>"Bioentry", :foreign_key => "biodatabase_id"
end


