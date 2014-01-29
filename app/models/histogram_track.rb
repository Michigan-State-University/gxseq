# == Schema Information
#
# Table name: tracks
#
#  assembly_id    :integer
#  created_at     :datetime
#  sample_id  :integer
#  id             :integer          not null, primary key
#  sample         :string(255)
#  source_term_id :integer
#  type           :string(255)
#  updated_at     :datetime
#

class HistogramTrack < Track
  belongs_to :sample
  
  def config
    " id    		: '#{self.id}',
      sample: '#{sample.id}',
      name  		: '#{name}',
      single	  : #{sample.single},
      type  		: 'DensityTrack',
      data  		: '#{root_path}/fetchers/base_counts',
      storeLocal: true,
      iconCls : '#{iconCls}',
      height 	: 100,
      hasPeaks : #{has_peaks},
      style: '#{style}'"
  end
  
  def name
    sample.name.gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))
  end
  
  def iconCls
    self.sample.iconCls
  end
  
  def custom_config
    "sample: '#{sample.id}',\n"
  end
  
  def type
      "type  		: 'DensityTrack',\n"
  end
  
  def path
    "#{sample.class.name}"
  end
  
  def has_peaks
    "#{sample.respond_to?('peaks') ? (sample.peaks.size > 0) : false}"
  end
  
  def style
    sample.respond_to?('track_style') ? sample.track_style : 'area'
  end
end

