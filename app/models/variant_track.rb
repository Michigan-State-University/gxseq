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

class VariantTrack < Track
  belongs_to :sample
  def path
    "Variants"
  end

  def config
    " id    		: '#{self.id}',
      sample: '#{sample.id}',
      name  		: '#{name}',
      sample    : '#{sample}',
      type  		: 'VariantTrack',
      data  		: '#{root_path}/variants/track_data',
      storeLocal: true,
      iconCls : '#{iconCls}',
      height 	: 100"
  end
  
  def name
    "#{sample.name.gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))}"+(sample ? "::#{(sample).gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))}" : '')
  end
  
  def custom_config
    "sample: '#{sample.id}',
     storeLocal: true,"
  end
  
  def iconCls
    "variant_track"
  end
end
