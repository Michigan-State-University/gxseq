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

class VariantTrack < Track
  belongs_to :sample
  def get_config
    base_config.merge(
      {
        :sample => sample.id,
        :sample_type => sample.class.name,
        :genotype_sample => genotype_sample,
        :storeLocal => true
      }
    )

  end
  
  def name
    "#{sample.name.gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))}"+(genotype_sample ? "::#{(genotype_sample).gsub("\\","\\\\\\\\").gsub("'",%q(\\\'))}" : '')
  end
  
  def iconCls
    "variant_track"
  end
  
  def data_path
    "#{root_path}/variants/track_data"
  end
  
  def folder
    "Variants"
  end
  
  def detail_text
    sample.traits.map{|t|"#{t.term.name}:#{trait.value}"}.join(" ")
  end
  
  def description_text
    sample.description
  end
end
