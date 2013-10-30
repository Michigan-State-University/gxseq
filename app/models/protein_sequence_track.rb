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

class ProteinSequenceTrack < Track
  def path
    "Genome"
  end
  
  def name
    "Protein Sequence"
  end
  
  def config
    " id    		: '#{self.id}',
      name  		: '#{self.name}',
      type  		: '#{self.class.name}',
      data  		: '#{root_path}/protein_sequence/genome',
      iconCls   : '#{iconCls}',
      height 	  : 100"
  end
  
  def iconCls
    "protein_sequence_track"
  end
  
end
