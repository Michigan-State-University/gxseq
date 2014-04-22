# == Schema Information
#
# Table name: components
#
#  created_at              :datetime
#  sample_id           :integer
#  id                      :integer          not null, primary key
#  combo_sample_id :integer
#  type                    :string(255)
#  updated_at              :datetime
#

class Component < ActiveRecord::Base
   validates_uniqueness_of :sample_id, :scope => [:combo_sample_id]
   belongs_to :combo_sample, :class_name => "Sample", :foreign_key => :combo_sample_id
   belongs_to :sample
end
