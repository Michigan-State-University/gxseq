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

class SixFrameTrack < Track
  def path
    "Genome"
  end
  
  def name
    "Genome Sequence"
  end
  
  def config
    "id    		: '#{self.id}',
      name  		: '#{self.name}',
      type  		: 'SequenceTrack',
      data  		: '#{root_path}/bioentries/track_data',
      iconCls : '#{iconCls}',
      storeLocal: true,
      height 	: 120"
  end
  
  def type
    "type : 'SequenceTrack',\n"
  end
  
  def iconCls
    "sequence_track"
  end
  
end
