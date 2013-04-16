class FeatureCount < ActiveRecord::Base
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature"
  belongs_to :experiment
  # Convert an array of feature_counts into graphable data
  def self.create_graph_data(feature_counts,hsh={})
    return [] if feature_counts.empty?
    base_counts = []
    # Dynamic data count keeps return set close to 1k
    max_data = hsh[:max_data]||(1000 / feature_counts.count.to_f).ceil
    count_type = hsh[:type]||'count'
    graph_length = feature_counts.first.seqfeature.length
    bioentry_id = feature_counts.first.seqfeature.bioentry_id
    data_count = [graph_length,max_data].min
    feature_counts.each do |fc|
      bc = fc.experiment.summary_data(fc.seqfeature.min_start,fc.seqfeature.max_end,data_count,fc.experiment.sequence_name(bioentry_id))
      next unless bc.length > 0
      total_sum = bc.inject{|sum,x| sum + x } || 1
      avg_read_length = total_sum / fc.count
      case count_type
      when 'count'
        base_counts << {
          :key => fc.experiment.name,
          :values => as_numbered_array(bc,graph_length).map{|data| {:base => data[0],:count =>(data[1]||0).to_i}}
        }
      when 'rpkm'
        pk = graph_length.to_f/1000
        pm = fc.experiment.total_mapped_reads.to_f/1000000
        base_counts << {
          :key => fc.experiment.name,
          :values => as_numbered_array(bc,graph_length).map{|data| {:base => data[0],:count => ((data[1]||0) / (pk*pm*avg_read_length)).round(4)}}
        }
      end
    end
    return base_counts
  end
  
  def self.as_numbered_array(array,position_max)
    # add index position
    counts = (0..(array.length)).zip(array)
    # change from 0..n counting - >  0..contig_length counting
    multiplier = (position_max/array.length.to_f)
    counts.each do |c|
      c[0] = ((c[0].to_i*multiplier).ceil).to_s
    end
    return counts
  end
end