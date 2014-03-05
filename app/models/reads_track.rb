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

class ReadsTrack < Track
  belongs_to :sample
  
  def get_config
    base_config.merge(
      {
        :sample => sample.id,
        :sample_type => sample.class.name,
        :single => sample.single,
        :storeLocal => true,
        :style => style
      }
    )

  end
  
  def iconCls
    sample.iconCls
  end
  
  def data_path
    "#{root_path}/track/reads/"
  end
  
  def folder
    "#{sample.class.name}"
  end
  
  def detail_text
    sample.traits.map{|t|"#{t.term.name}:#{t.value}"}.join(" ")
  end
  
  def description_text
    sample.description
  end
  
  def style
    sample.respond_to?('track_style') ? sample.track_style : 'area'
  end
end
