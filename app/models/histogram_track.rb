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

class HistogramTrack < Track
  belongs_to :sample
  def get_config
    base_config.merge(
      {
        :sample => sample.id,
        :sample_type => sample.class.name,
        :single => sample.single,
        :storeLocal => true,
        :hasPeaks => has_peaks,
        :style => style
      }
    )
  end
  
  def iconCls
    self.sample.iconCls
  end
  
  def data_path
    "#{root_path}/fetchers/base_counts"
  end
  
  def folder
    "#{sample.class.name}"
  end
  
  def track_type
    "DensityTrack"
  end
  
  def detail_text
    sample.traits.map{|t|"#{t.term.name}:#{trait.value}"}.join(" ")
  end
  
  def description_text
    sample.description
  end
  
  def has_peaks
    "#{sample.respond_to?('peaks') ? (sample.peaks.size > 0) : false}"
  end
  
  def style
    sample.respond_to?('track_style') ? sample.track_style : 'area'
  end
end

