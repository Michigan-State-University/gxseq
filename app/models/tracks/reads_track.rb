# == Schema Information
#
# Table name: tracks
#
#  assembly_id    :integer
#  created_at     :datetime
#  experiment_id  :integer
#  id             :integer          not null, primary key
#  sample         :string(255)
#  source_term_id :integer
#  type           :string(255)
#  updated_at     :datetime
#

class ReadsTrack < Track
  belongs_to :experiment
  
  def config
    " id    		: '#{self.id}',
      experiment: '#{experiment.id}',
      name  		: '#{name}',
      single	  : #{experiment.single},
      type  		: 'ReadsTrack',
      data  		: '#{root_path}/reads/track_data',
      iconCls : '#{iconCls}',
      storeLocal: true,
      height 	: 100"
  end
  
  def name
    experiment.name.gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))
  end
  
  def iconCls
    self.experiment.iconCls
  end
  
  def custom_config
    "experiment: '#{experiment.id}',\n"
  end
  
  def type
      "type  		: 'ReadsTrack',\n"
  end
  
  def path
    "#{experiment.class.name}"
  end
  
end
