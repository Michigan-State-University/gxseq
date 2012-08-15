class ModelsTrack < Track
  def path
    "Genome"
  end
  
  def name
    "Gene Models"
  end
  
  def config
    " id: '#{self.id}',
      name: '#{self.name}',
      showAdd: true,
      bioentry: '#{self.bioentry.id}',
      source: '#{self.source}
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

