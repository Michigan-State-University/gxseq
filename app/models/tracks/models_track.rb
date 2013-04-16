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

