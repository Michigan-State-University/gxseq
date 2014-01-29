# == Schema Information
#
# Table name: feature_counts
#
#  count            :integer
#  created_at       :datetime
#  sample_id    :integer
#  id               :integer          not null, primary key
#  normalized_count :decimal(10, 2)
#  seqfeature_id    :integer
#  unique_count     :integer
#  updated_at       :datetime
#

class FeatureCount < ActiveRecord::Base
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature"
  belongs_to :sample
  scope :with_trait, lambda {|term_id| includes(:sample => :traits).where{traits.term_id == my{term_id}}}
  # Convert an array of feature_counts into graphable data
  def self.create_base_data(feature_counts,hsh={})
    return [] if feature_counts.empty?
    base_counts = []
    # Dynamic data count keeps return set close to 1k
    max_data = hsh[:max_data]||(1000 / feature_counts.count.to_f).ceil
    count_type = hsh[:type]||'count'
    graph_length = feature_counts.first.seqfeature.length
    bioentry_id = feature_counts.first.seqfeature.bioentry_id
    data_count = [graph_length,max_data].min
    feature_counts.each do |fc|
      bc = fc.sample.summary_data(fc.seqfeature.min_start,fc.seqfeature.max_end,data_count,fc.sample.sequence_name(bioentry_id))
      if bc.length == 0
        next
      end
      case count_type
      when 'count'
        base_counts << {
          :key => fc.sample.name,
          :values => as_numbered_array(bc,graph_length).map{|data| {:base => data[0],:count =>(data[1]||0).to_i}}
        }
      when 'rpkm'
        # TODO : test alternatives, not currently in use
        total_sum = bc.inject{|sum,x| sum + x } || 1
        avg_read_length = total_sum / fc.count
        pk = graph_length.to_f/1000
        pm = fc.sample.total_mapped_reads.to_f/1000000
        base_counts << {
          :key => fc.sample.name,
          :values => as_numbered_array(bc,graph_length).map{|data| {:base => data[0],:count => ((data[1]||0) / (pk*pm*avg_read_length)).round(4)}}
        }
      end
    end
    return base_counts
  end
  
  def self.create_sample_data(feature_counts,hsh={})
    value_type=hsh[:value_type]||'normalized_count'
    # make multiple series. One for each unique trait value
    if(hsh[:group_trait]&&Biosql::Term.find_by_term_id(hsh[:group_trait]))
      all_series ={}
      maxCount = 0;
      logger.info "\n\nFOS\n\n\n\n"
      feature_counts.with_trait(hsh[:group_trait])
      .except(:order)
      .order{[sample.traits.value.asc,sample.name.asc]}
      .each do |fc|
        if( this_trait = fc.sample.traits.first )
          all_series[this_trait.value] ||= {:id => this_trait.id,:series => this_trait.value,:values => []}
          all_series[this_trait.value][:values] << {:x => fc.sample.name, :y => fc.send(value_type.to_sym)}
          maxCount=all_series[this_trait.value][:values].length if all_series[this_trait.value][:values].length > maxCount
        end
      end
      #Pad any blank slots with 0
      all_series.each do |key,value|
        while value[:values].length < maxCount
          value[:values] << {:x => "?#{value[:values].length+1}", :y => 0}
        end
      end
      return all_series.values
    else
      # only one series for a basic line
      item = {
        :id => feature_counts.first.seqfeature_id,
        :series => feature_counts.first.seqfeature.label,
        :values => []
      }
      feature_counts.each do |f_count|
        item[:values] << {:x => f_count.sample.name, :y => f_count.send(value_type.to_sym) }
      end
      return[item]
    end
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
