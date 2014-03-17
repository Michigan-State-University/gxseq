# == Schema Information
#
# Table name: samples
#
#  a_op               :string(255)
#  assembly_id        :integer
#  b_op               :string(255)
#  concordance_set_id :integer
#  created_at         :datetime
#  description        :string(2000)
#  file_name          :string(255)
#  group_id           :integer
#  id                 :integer          not null, primary key
#  mid_op             :string(255)
#  name               :string(255)
#  sequence_name      :string(255)
#  show_negative      :string(255)
#  state              :string(255)
#  total_count        :integer
#  type               :string(255)
#  updated_at         :datetime
#  user_id            :integer
#

class Synthetic < Sample
  has_one :ratio_track, :foreign_key => "sample_id", :dependent => :destroy
  has_many :a_components, :foreign_key => :synthetic_sample_id, :dependent => :destroy
  has_many :b_components, :foreign_key => :synthetic_sample_id, :dependent => :destroy
  has_many :components, :foreign_key => :synthetic_sample_id
  validates_presence_of :a_components
  validates_presence_of :b_components
  accepts_nested_attributes_for :a_components, :allow_destroy => true
  accepts_nested_attributes_for :b_components, :allow_destroy => true
  
  def self.to_label
    "Ratio"
  end
  ##Specialized methods
  def update_assets
    update_attribute(:state, "ready")
  end
  
  def create_tracks
    create_ratio_track(:assembly => assembly) unless ratio_track
  end
  
  def summary_data(start, stop, num, chrom)
    a_results = []
    a_components.each do |a|
      a_results << a.sample.summary_data(start, stop, num, chrom)
    end
    b_results = []
    b_components.each do |b|
      b_results << b.sample.summary_data(start, stop, num, chrom)
    end
    a_merged = merge_multiple_results(a_op,a_results)
    b_merged = merge_multiple_results(b_op,b_results)
    data = merge_results(mid_op,a_merged,b_merged)
    # Fix Infinity
    data.fill{|i| data[i]==Float::INFINITY ? 1 : data[i]}
    # convert to LOG(10)
    data.fill{|i| data[i].round(4)==0 ? 0 : Math.log(data[i].round(4))}
    return data
  end

  ##Track Config
  def iconCls
    "synthetic_track"
  end
  
  ##Class Specific
  
  def merge_results(op, a_results, b_results)
    data = []
    case op
    when "/"
      a_results.each_with_index do |a,idx|
        data << a/b_results[idx]
      end
    when "-"
      a_results.each_with_index do |a,idx|
        data << a-b_results[idx]
      end
    end
    return data
  end

  def merge_multiple_results(op, results)
    data = []
    comp_count = results.size
    case op
    when "avg"
      results[0].each_with_index do |r, idx|
        avg=0.0
        comp_count.times do |i|
          avg+= results[i][idx].to_f
        end
        data<< avg/comp_count
      end
    when "sum"
      results[0].each_with_index do |r, idx|
        sum=0.0
        comp_count.times do |i|
          sum+= results[i][idx].to_f
        end
        data<< sum
      end
    when "max"
      results[0].each_with_index do |r, idx|
        vals=[]
        comp_count.times do |i|
          vals<< results[i][idx].to_f
        end
        data<< vals.max
        end
      end
    return data
  end
  
  # calculates and returns a MAD score
  def median_absolute_deviation(concordance_item,count=2000)
    length = concordance_item.bioentry.length
    data = summary_data(1,length,[count,length].min,concordance_item.reference_name)
    # Get Median
    median = DescriptiveStatistics::Stats.new(data).median
    # Get absolute deviation
    abs_dev = data.map{|d| (d-median).abs}
    # get the absolute deviation median
    abs_dev_median = DescriptiveStatistics::Stats.new(abs_dev).median
    # multiply by constant factor == .75 quantile of assumed distribution
    # .75 quantile of normal distribution == 1.4826
    1.4826 * abs_dev_median
  end
  
  # returns the median
  def median(concordance_item,count=2000)
    length = concordance_item.bioentry.length
    data = summary_data(1,length,[count,length].min,concordance_item.reference_name)
    # Get Median
    median = DescriptiveStatistics::Stats.new(data).median
  end
  
  def standard_deviation(concordance_item,count=1000)
    length = concordance_item.bioentry.length
    data = summary_data(1,length,count,concordance_item.reference_name)
    # fix infinity
    absMax = data.map(&:abs).reject{|x|x==Float::INFINITY}.uniq
    absMax = absMax.max
    data.fill{|i| data[i]==Float::INFINITY ? 1 : data[i]}
    DescriptiveStatistics::Stats.new(data).standard_deviation
  end
  
end

