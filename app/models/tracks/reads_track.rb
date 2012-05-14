class ReadsTrack < Track
  belongs_to :experiment
  
  def config
    " id    		: '#{self.id}',
      experiment: '#{experiment.id}',
      name  		: '#{name}',
      bioentry 	: '#{bioentry.id}',
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