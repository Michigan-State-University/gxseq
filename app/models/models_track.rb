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
  
  def get_config
    base_config.merge(
      {
        :source => self.source_term_id,
        :storeLocal => true,
        :showControls =>  true
      }
    )

  end
  
  def name
    "#{source_term.name}: Gene Models"
  end
  
  def iconCls
    "gene_track"
  end
  
  def data_path
    "#{root_path}/fetchers/gene_models"
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

