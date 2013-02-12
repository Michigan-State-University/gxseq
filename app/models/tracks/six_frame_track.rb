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
      bioentry 	: '#{self.bioentry.id}',
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

