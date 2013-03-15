class Transcriptome < Assembly
  def default_feature_definition
    blast_runs.first ?  "blast_#{blast_runs.first.id}": 'description'
  end
end