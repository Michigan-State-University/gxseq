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
  has_one :histogram_track, :foreign_key => "sample_id", :dependent => :destroy
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
    create_histogram_track(:assembly => assembly) unless histogram_track
  end
  
  def display_html
    a_text=b_text=''
    if(a_components.count>1)
      a_text="<b style='color:blue'>#{a_op}</b>(#{a_components.collect{|c| c.sample.display_html}.join(", ")})"
    elsif(a_components.first)
      a_text="(#{a_components.first.sample.display_html})"
    end
    if(b_components.count>1)
      b_text="<b style='color:blue'>#{b_op}</b>(#{b_components.collect{|c| c.sample.display_html}.join(", ")})"
    elsif(b_components.first)
      b_text="(#{b_components.first.sample.display_html})"
    end
    doc="<div>
      <div style='margin-left:1em'>#{a_text}</div>
        <div style='margin-left:1em'><b style='color:blue'>#{mid_op}</b></div>
      <div style='margin-left:1em'>#{b_text}</div>
    </div>".html_safe
    return doc
  end
  
  def summary_data(num=200)
    a_summaries = []
    a_components.each do |a|
      a_summaries << a.sample.summary_data(num)
    end    
    b_summaries = []
    b_components.each do |b|
      b_summaries << b.sample.summary_data(num)
    end
    a_merged = merge_multiple_results(a_op,a_summaries,false)
    b_merged = merge_multiple_results(b_op,b_summaries,false)
    return merge_results(mid_op,a_merged,b_merged,false)
  end
  
  def results_query(start, stop, bases)
    a_results = []
    a_components.each do |a|
      a_results << a.sample.results_query(start, stop, bases)
    end
    b_results = []
    b_components.each do |b|
      b_results << b.sample.results_query(start, stop, bases)
    end
    a_merged = merge_multiple_results(a_op,a_results)
    b_merged = merge_multiple_results(b_op,b_results)
    return merge_results(mid_op,a_merged,b_merged)
  end
  
  # def base_counts
  #   bioentry.biosequence_without_seq.length
  # end

  ##Track Config
  def iconCls
    "synthetic_track"
  end
  
  def single
    "false"
  end
  
  ##Class Specific
  
  def merge_results(op, a_results, b_results, has_pos = true)
    data = []
    case op
    when "/"
      a_results.each_with_index do |a,idx|
        data << (has_pos ? [a[0],(a[1]/b_results[idx][1])] : (a/b_results[idx]))
      end
    when "-"
      a_results.each_with_index do |a,idx|
        data << (has_pos ? [a[0],(a[1]-b_results[idx][1])] : a-b_results[idx])
      end
    end
    return data
  end

  def merge_multiple_results(op, results, has_pos = true)
    data = []
    comp_count = results.size
    case op
    when "avg"
      results[0].each_with_index do |r, idx|
        avg=0.0
        comp_count.times do |i|
          avg+= (has_pos ? results[i][idx][1].to_f : results[i][idx].to_f)
        end
        data<< (has_pos ? [r[idx][0],avg/comp_count] : avg/comp_count)
      end
    when "sum"
      results[0].each_with_index do |r, idx|
        sum=0.0
        comp_count.times do |i|
          sum+= (has_pos ? results[i][idx][1].to_f : results[i][idx].to_f)
        end
        data<< (has_pos ? [r[0],sum] : sum)
      end
    when "max"
      results[0].each_with_index do |r, idx|
        vals=[]
        comp_count.times do |i|
          vals<< (has_pos ? results[i][idx][1].to_f : results[i][idx].to_f)
        end
        data<< (has_pos ? [r[idx][0],vals.max] : vals.max)
        end
      end
    return data
  end
   
end

