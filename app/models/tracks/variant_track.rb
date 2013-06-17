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

class VariantTrack < Track
  belongs_to :experiment
  def path
    "Variants"
  end

  def config
    " id    		: '#{self.id}',
      experiment: '#{experiment.id}',
      name  		: '#{name}',
      sample    : '#{sample}',
      type  		: 'VariantTrack',
      data  		: '#{root_path}/variants/track_data',
      storeLocal: true,
      iconCls : '#{iconCls}',
      height 	: 100"
  end
  
  def name
    "#{experiment.name.gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))}"+(sample ? "::#{(sample).gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))}" : '')
  end
  
  def custom_config
    "experiment: '#{experiment.id}',
     storeLocal: true,"
  end
  
  def iconCls
    "silk_bricks"
  end
end
