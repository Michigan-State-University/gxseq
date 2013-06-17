# == Schema Information
#
# Table name: components
#
#  created_at              :datetime
#  experiment_id           :integer
#  id                      :integer          not null, primary key
#  synthetic_experiment_id :integer
#  type                    :string(255)
#  updated_at              :datetime
#

class Component < ActiveRecord::Base
   validates_uniqueness_of :experiment_id, :scope => [:synthetic_experiment_id,:type]
   belongs_to :experiment
end
