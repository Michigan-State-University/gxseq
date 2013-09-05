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

class ModelsTrack < Track
  belongs_to :source_term, :class_name => "Biosql::Term", :foreign_key => :source_term_id
  def path
    "Genome"
  end
  
  def name
    "#{source_term.name}: Gene Models"
  end
  
  def config
    " id: '#{self.id}',
      name: '#{self.name}',
      showAdd: true,
      source: '#{self.source_term_id}',
      type: '#{self.class.name}',
      data: '#{root_path}/fetchers/gene_models',
      edit: '#{root_path}/edits/model',
      height: 200,
      storeLocal: true,
      iconCls: '#{iconCls}',
      showControls: true"
  end
  
  def iconCls
    "gene_track"
  end
end

