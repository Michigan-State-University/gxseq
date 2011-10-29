class VariantTrack < Track
  belongs_to :experiment
  def path
    "Variants"
  end

  def config
    " id    		: '#{self.id}',
      experiment: '#{experiment.id}',
      name  		: '#{name}',
      bioentry 	: '#{bioentry.id}',
      type  		: 'VariantTrack',
      data  		: '#{root_path}/variants/track_data',
      storeLocal: true,
      iconCls : '#{iconCls}',
      height 	: 100"
  end
  
  def name
    experiment.name.gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))
  end
  
  def custom_config
    "experiment: '#{experiment.id}',
     storeLocal: true,"
  end
  
  def iconCls
    "silk_bricks"
  end
end