class FeatureCount < ActiveRecord::Base
  belongs_to :seqfeature
  belongs_to :experiment
end