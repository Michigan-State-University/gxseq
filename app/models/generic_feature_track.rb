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

class GenericFeatureTrack < Track
  belongs_to :source_term, :class_name => "Biosql::Term", :foreign_key => :source_term_id
  def get_config
    base_config.merge(
      {
        :showControls => true
      }
    )

  end
  
  def name
    "#{source_term.name}: Features"
  end
  
  def iconCls
    "gene_track"
  end
  
  def data_path
    "#{root_path}/generic_feature/gene_models"
  end
  
  def folder
    "Genome"
  end

  # TODO: What should we display here 
  # def detail_text
  # end
  # 
  # def description_text
  # end
  
end
