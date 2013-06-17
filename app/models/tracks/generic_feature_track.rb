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

class GenericFeatureTrack < Track
  belongs_to :source_term, :class_name => "Biosql::Term", :foreign_key => :source_term_id
  def path
    "Genome"
  end
  
  def name
    "#{source_term.name}: Features"
  end
  
  def config
    " id: '#{self.id}',
      name: '#{name}',
      showAdd: true,
      type: '#{self.class.name}',
      data: '#{root_path}/generic_feature/gene_models',
      height: 150,
      iconCls: '#{iconCls}',
      showControls: true"
  end
  
  def iconCls
    "gene_track"
  end
end
