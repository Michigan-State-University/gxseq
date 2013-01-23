class FeatureCount < ActiveRecord::Base
  belongs_to :seqfeature
  belongs_to :experiment
  # Convert an array of feature_counts into graphable data
  def self.create_graph_data(feature_counts,hsh={})
    return [] if feature_counts.empty?
    base_counts = []
    return_cnt = hsh[:cnt]||300
    cutoff = hsh[:cutoff]||500
    count_type = hsh[:type]||'count'
    graph_length = feature_counts.first.seqfeature.length
    bioentry_id = feature_counts.first.seqfeature.bioentry_id
    feature_counts.each do |fc|
      bc = fc.experiment.summary_data(fc.seqfeature.min_start,fc.seqfeature.max_end,(graph_length>cutoff ? return_cnt : graph_length),fc.experiment.sequence_name(bioentry_id))
      total_sum = bc.inject{|sum,x| sum + x } || 1
      avg_read_length = total_sum / fc.count
      case count_type
      when 'count'
        #do nothing
        base_counts << bc
      when 'rpkm'  #compute the rpkm (per position) from the mapped reads
        # pk = graph_length.to_f/1000
        # pm = l.ests_count.to_f/1000000
        # base_counts << bc.collect{|b| b / (pk*pm*avg_read_length)}
      end
    end
    if(graph_length>cutoff)
      counts = ('0'..(return_cnt.to_s)).zip(*base_counts)
      #change from 0..n counting - >  0..contig_length counting
      multiplier = (graph_length/return_cnt.to_f)
      counts.each do |c|
        c[0] = ((c[0].to_i*multiplier).ceil).to_s
      end
    else
      counts = ('0'..graph_length.to_s).zip(*base_counts)
    end
    return counts.inspect.gsub(/\"/,"'").gsub(/nil/,"0")
  end
end