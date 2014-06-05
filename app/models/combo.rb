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

class Combo < Sample
  has_one :combo_track, :foreign_key => "sample_id", :dependent => :destroy
  has_many :a_components, :foreign_key => :combo_sample_id, :dependent => :destroy
  has_many :b_components, :foreign_key => :combo_sample_id, :dependent => :destroy
  has_many :components, :foreign_key => :combo_sample_id
  validates_presence_of :a_components
  validates_presence_of :b_components
  accepts_nested_attributes_for :a_components, :allow_destroy => true
  accepts_nested_attributes_for :b_components, :allow_destroy => true
  
  def self.to_label
    "Combo"
  end
  ##Specialized methods
  def update_assets
    update_attribute(:state, "ready")
  end
  
  def create_tracks
    create_combo_track(:assembly => assembly) unless combo_track
  end
  
  def summary_data(start, stop, num, bioentry)
    a_results = []
    a_components.each do |a|
      a_results << a.sample.summary_data(start, stop, num, bioentry)
    end
    b_results = []
    b_components.each do |b|
      b_results << b.sample.summary_data(start, stop, num, bioentry)
    end
    a_merged = merge_multiple_results(a_op,a_results)
    b_merged = merge_multiple_results(b_op,b_results)
    data = merge_results(mid_op,a_merged,b_merged)
    return data
  end

  ##Track Config
  def iconCls
    "combo_track"
  end
  
  ##Class Specific
  def merge_results(op, a_results, b_results)
    data = []
    case op
    when "/"
      a_results.each_with_index do |a,idx|
        if a.round(10)==0.0 or b_results[idx].round(10)==0.0
          data << 0
        else
          data << Math.log(a/b_results[idx]).round(4)
        end
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
  
end

