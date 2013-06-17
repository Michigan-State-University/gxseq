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

