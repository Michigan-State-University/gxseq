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

class RnaSeq < Sample
  has_one :reads_track, :foreign_key => "sample_id", :dependent => :destroy
  has_one :histogram_track, :foreign_key => "sample_id", :dependent => :destroy
  has_many :feature_counts, :foreign_key => "sample_id", :dependent => :delete_all
  has_one :bam, :foreign_key => "sample_id"
  has_one :big_wig, :foreign_key => "sample_id"
  has_one :forward_big_wig, :foreign_key => "sample_id"
  has_one :reverse_big_wig, :foreign_key => "sample_id"
  smoothable
  
  def asset_types
    {"Bam" => "Bam","BigWig" => "BigWig","Forward BigWig" => "ForwardBigWig","Reverse BigWig" => "ReverseBigWig"}
  end
  # overrides load to include big_wig generation
  def load_asset_data
    return false unless super
    begin
      self.update_attribute(:total_count, total_mapped_reads)
      if(bam && !big_wig)
        self.create_big_wig(:data => bam.create_big_wig)
        big_wig.load if big_wig
      end
      if(bam && !forward_big_wig)
        self.create_forward_big_wig(:data => bam.create_big_wig(:strand => '+'))
        forward_big_wig.load if forward_big_wig
      end
      if(bam && !reverse_big_wig)
        self.create_reverse_big_wig(:data => bam.create_big_wig(:strand => '-'))
        reverse_big_wig.load if reverse_big_wig
      end
      return true
    rescue => e
      puts e
      return false
    end
  end
  
  # generates tracks depending on availabale assets
  # creates ReadsTracks if a bam is present otherwise HistogramTracks are created
  def create_tracks
    if(bam)
      create_reads_track(:assembly => assembly) unless reads_track
      # replace the histogram track as soon as we have a bam
      histogram_track.destroy if histogram_track
    elsif(big_wig)
      create_histogram_track(:assembly => assembly) unless histogram_track
    else
      #remove any existing tracks
      histogram_track.destroy if histogram_track
      reads_track.destroy if reads_track
    end
  end
  
  # searches for a read by id and returns alignment data. See bam#find_read for details
  def find_read(read_id, bioentry, pos)
    bam.find_read(read_id, sequence_name(bioentry), pos)
  end
  # returns histogram data see big_wig#summary_data for details
  def summary_data(start,stop,num,bioentry,opts={})
    # switch signs if strand is flipped
    if flip_strand=='true' && opts[:strand]=='+'
      opts[:strand]='-'
    elsif flip_strand=='true' && opts[:strand]=='-'
      opts[:strand]='+'
    end
    # grab data from the requested bigWig
    if opts[:strand]=='+'
      return (forward_big_wig ? forward_big_wig.summary_data(start,stop,num,sequence_name(bioentry)).map(&:to_f) : [])
    elsif opts[:strand]=='-'
      return (reverse_big_wig ? reverse_big_wig.summary_data(start,stop,num,sequence_name(bioentry)).map(&:to_f) : [])
    else
      return (self.big_wig ? big_wig.summary_data(start,stop,num,sequence_name(bioentry)).map(&:to_f) : [])
    end
  end
  # returns reads in chromosome range see bam#get_reads
  def get_reads(start, stop, chrom)
    bam.get_reads(start, stop, chrom)
  end
  # returns processed reads as formatted text see bam#get_reads_text
  def get_reads_text(start, stop, chrom,opts)
    if show_negative && flip_strand=='true'
      opts[:flip_strand] = true
    end
    bam.get_reads_text(start, stop, chrom,opts)
  end
  # returns the max value stored in the big_wig
  # if a sequence_name is supplied it will return max for that sequence only
  def max(chrom='')
    begin
      if single
        big_wig.max(chrom)
      else
        [forward_big_wig.max(chrom),reverse_big_wig.max(chrom)].max
      end
    rescue
      1
    end
  end
  # returns the total count of mapped reads from the bam
  def total_mapped_reads
    bam.try(:total_mapped_reads) || 0
  end
  
  ##Track Config
  def iconCls
    "rna_seq_track"
  end

  # returns option for track config
  # true for one single canvas, false for two pos/neg canvas
  def single
    # Use pos/neg canvas for single stranded samples
    show_negative =='true' ? false : true
  end
  
  def track_style
    'area'
  end
end
