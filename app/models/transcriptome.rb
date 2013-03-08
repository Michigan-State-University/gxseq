class Transcriptome < Assembly
  def default_feature_definition
    blast_runs.first.try(:name_with_id)||'description'
  end
end