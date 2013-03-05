class HistogramTrack < Track
  belongs_to :experiment
  
  def config
    " id    		: '#{self.id}',
      experiment: '#{experiment.id}',
      name  		: '#{name}',
      single	  : #{experiment.single},
      type  		: 'MicroarrayTrack',
      data  		: '#{root_path}/fetchers/base_counts',
      storeLocal: true,
      iconCls : '#{iconCls}',
      height 	: 100,
      peaks : #{peaks}"
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
      "type  		: 'MicroarrayTrack',\n"
  end
  
  def path
    "#{experiment.class.name}"
  end
  
  def peaks
    "#{experiment.respond_to?('peaks') ? (experiment.peaks.size > 0) : false}"
  end
  
end


# == Schema Information
#
# Table name: tracks
#
#  id            :integer(38)     not null, primary key
#  type          :string(255)
#  bioentry_id   :integer(38)
#  experiment_id :integer(38)
#  created_at    :datetime
#  updated_at    :datetime
#

