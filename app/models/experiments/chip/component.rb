class Component < ActiveRecord::Base
   validates_uniqueness_of :experiment_id, :scope => [:synthetic_experiment_id,:type]
   belongs_to :experiment
end

# == Schema Information
#
# Table name: components
#
#  id                      :integer(38)     not null, primary key
#  type                    :string(255)
#  experiment_id           :integer(38)
#  synthetic_experiment_id :integer(38)
#  created_at              :datetime
#  updated_at              :datetime
#

