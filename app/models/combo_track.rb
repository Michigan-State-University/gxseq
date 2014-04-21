class ComboTrack < Track
  belongs_to :sample
  def get_config
    base_config.merge(
      {
        :sample => sample.id,
        :sample_type => sample.class.name,
        :storeLocal => true
      }
    )
  end
  
  def iconCls
    'blocks'
  end
  
  def data_path
    "#{root_path}/track/combo/"
  end
  
  def folder
    "Combo"
  end
  
  def track_type
    "ComboTrack"
  end
  
  def detail_text
    sample.traits.map{|t|"#{t.term.name}:#{t.value}"}.join(" ")
  end
  
  def description_text
    sample.description
  end
end
