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
  
  def summary_data(start, stop, num, bioentry)
    a_results = []
    a_components.each do |a|
      a_conc = a.sample.concordance_items.with_bioentry(bioentry)[0]
      a_results << a.sample.summary_data(start, stop, num, a_conc.reference_name)
    end
    b_results = []
    b_components.each do |b|
      b_conc = b.sample.concordance_items.with_bioentry(bioentry)[0]
      b_results << b.sample.summary_data(start, stop, num, b_conc.reference_name)
    end
    a_merged = merge_multiple_results(a_op,a_results)
    b_merged = merge_multiple_results(b_op,b_results)
    data = merge_results(mid_op,a_merged,b_merged)

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
  
  # Override to use bioentry instead of concordance name
  # calculates and returns a MAD score
  def median_absolute_deviation(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    #logger.info "\n\ndata:#{data}\n\n"
    # Get Median
    median = DescriptiveStatistics::Stats.new(data).median
    # Get absolute deviation
    abs_dev = data.map{|d| (d-median).abs}
    #logger.info "\n\nABSDEV:\n#{abs_dev.inspect}\n\n"
    # get the absolute deviation median
    abs_dev_median = DescriptiveStatistics::Stats.new(abs_dev).median
    # multiply by constant factor == .75 quantile of assumed distribution
    # .75 quantile of normal distribution == 1.4826
    1.4826 * abs_dev_median
  end
  
  # returns the median
  def median(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    median = DescriptiveStatistics::Stats.new(data).median
  end
  
  # returns the stddev
  def stddev(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    DescriptiveStatistics::Stats.new(data).standard_deviation
  end
  
  # returns the mean
  def mean(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    DescriptiveStatistics::Stats.new(data).mean
  end
  
  def json_summary(opts={})
    bioentry = opts[:bioentry]||bioentries.first
    return unless bioentry
    count = opts[:density]||1000
    #name = concordance_items.with_bioentry(bioentry.id)[0].try(:reference_name)
    gap = bioentry.length/count.to_f
    data = [{
      :id  => bioentry.id,
      :name => bioentry.accession,
      :values => summary_data(0,bioentry.length,count,bioentry).collect.with_index{|d,i|
        { :x => (i*gap).to_i, :y => d }
      }
    }].to_json
  end
end

