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

class ReadsTrack < Track
  belongs_to :sample
  
  def config
    " id    		: '#{self.id}',
      sample: '#{sample.id}',
      name  		: '#{name}',
      single	  : #{sample.single},
      type  		: 'ReadsTrack',
      data  		: '#{root_path}/reads/track_data',
      iconCls : '#{iconCls}',
      storeLocal: true,
      height 	: 100"
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
      "type  		: 'ReadsTrack',\n"
  end
  
  def path
    "#{sample.class.name}"
  end
  
end
