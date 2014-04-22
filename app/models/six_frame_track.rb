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

class SixFrameTrack < Track
  def get_config
    base_config.merge(
      {
        :storeLocal => true,
      }
    )

  end
  
  def name
    "Genome Sequence"
  end
  
  def iconCls
    "sequence_track"
  end
  
  def data_path
    "#{root_path}/track/sequence/"
  end
  
  def folder
    "Genome"
  end
  
  def track_type
    "SequenceTrack"
  end
  
  # TODO: What should we display here 
  # def detail_text
  # end
  # 
  # def description_text
  # end
end
