# == Schema Information
#
# Table name: experiments
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

class ChipChip < Experiment
  has_many :peaks, :foreign_key => "experiment_id"
  has_one :histogram_track, :foreign_key => "experiment_id", :dependent => :destroy
  has_one :big_wig, :foreign_key => "experiment_id"
  has_one :wig, :foreign_key => "experiment_id"  
  has_peaks
  smoothable

  ##Specialized Methods
  def asset_types
    {"bigWig" => "BigWig", "wig" => "Wig"}
  end
  
  def load_asset_data
    return false unless super
    begin
      # check for big_wig; create it if we can
      if(wig && !big_wig)
        self.create_big_wig(:data => wig.create_big_wig(self.get_chrom_file.path))
        big_wig.load if big_wig
      end
      # compute associated data
      # TODO: add compute peaks flag and peak upload
      self.update_attribute(:state,"computing")
      compute_peaks
      self.update_attribute(:state,"ready")
      return true
    rescue
      puts "** Error loading assets:\n#{$!}"
      return false
    end
  end
  
  # TODO: should we remove peaks? What about uploaded peaks. Should we remove big_wig if we have a wig?
  def remove_asset_data
    super
  end
  
  def create_tracks
    create_histogram_track(:assembly => assembly) unless histogram_track
  end

  def summary_data(start,stop,num,chrom)
    big_wig.summary_data(start,stop,num,chrom).map(&:to_f)
  end

  ##Track Config
  def iconCls
    "chip_chip_track"
  end

  def single
    self.show_negative == "No" ? "true" : "false"
  end

  ##Class Specific
  def max(chrom='')
    begin
      big_wig.max(chrom)
    rescue
      1
    end
  end

end

