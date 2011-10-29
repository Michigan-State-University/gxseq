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
      bioentry 	: '#{self.bioentry.id}',
      type  		: '#{self.class.name}',
      data  		: '#{root_path}/protein_sequence/genome',
      iconCls   : '#{iconCls}',
      height 	  : 100"
  end
  
  def iconCls
    "protein_sequence_track"
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

