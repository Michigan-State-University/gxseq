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

class ChipSeq < Sample
  has_one :histogram_track, :foreign_key => "sample_id", :dependent => :destroy
  has_one :reads_track, :foreign_key => "sample_id", :dependent => :destroy
  has_one :bam, :foreign_key => "sample_id"
  has_one :big_wig, :foreign_key => "sample_id"
  has_one :wig, :foreign_key => "sample_id"
  has_peaks
  smoothable
  
  ##Specialized Methods
  def asset_types
    {"Bam" => "Bam","bigWig" => "BigWig", "wig" => "Wig"}
  end  
  
  def load_asset_data
    return false unless super
    begin
      if(bam && !big_wig)
        self.create_big_wig(:data => bam.create_big_wig)
        big_wig.load if big_wig
      elsif(wig && !big_wig)
        self.create_big_wig(:data => wig.create_big_wig(self.get_chrom_file.path))
        big_wig.load if big_wig
      end
      # compute associated data
      # TODO: add compute peaks flag and peak upload
      self.update_attribute(:state,"computing")
      compute_peaks(:remove => true)
      self.update_attribute(:state,"ready")
      return true
    rescue
      puts "** Error loading assets:\n#{$!}"
      return false
    end
  end
  
  def remove_asset_data
    super
  end
  
  def create_tracks
    if(bam)
      create_reads_track(:assembly => assembly) unless reads_track
      histogram_track.destroy if histogram_track
    else
      create_histogram_track(:assembly => assembly) unless histogram_track
      reads_track.destroy if reads_track
    end
  end
  # returns reads in chromosome range see bam#get_reads
  def get_reads(start, stop, chrom)
    bam.get_reads(start, stop, chrom)
  end
  # returns processed reads as formatted text see bam#get_reads_text
  def get_reads_text(start, stop, chrom,opts)
    bam.get_reads_text(start, stop, chrom,opts)
  end
  # searches for a read by id and returns alignment data. See bam#find_read for details
  def find_read(read_id, chrom, pos)
    bam.find_read(read_id, chrom, pos)
  end
  # returns histogram data see big_wig#summary_data for details
  def summary_data(start,stop,num,bioentry)
    self.big_wig ? big_wig.summary_data(start,stop,num,sequence_name(bioentry)).map(&:to_f) : []
  end

  ##Class Specific
  def max(chrom='')
    begin
      big_wig.max(chrom)
    rescue
      1
    end
  end
  
  ##Track Config
  def iconCls
    "chip_seq_track"
  end

  def single
    "true"
  end
  
  # def track_style
  #   'area'
  # end
  

end
