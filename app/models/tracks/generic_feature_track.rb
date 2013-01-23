class GenericFeatureTrack < Track
  def path
    "Genome"
  end
  
  def name
    "All Features"
  end
  
  def config
    " id: '#{self.id}',
      name: '#{name}',
      showAdd: true,
      bioentry: '#{self.bioentry.id}',
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