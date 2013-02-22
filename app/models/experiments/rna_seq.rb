class RnaSeq < Experiment
  has_many :reads_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  has_many :histogram_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  has_many :feature_counts, :foreign_key => "experiment_id", :dependent => :destroy
  has_one :bam, :foreign_key => "experiment_id"
  has_one :big_wig, :foreign_key => "experiment_id"
  after_save :update_bioentry_concordance_from_bam
  smoothable
  
  def asset_types
    {"Bam" => "Bam","BigWig" => "BigWig"}
  end
  # overrides load to include big_wig generation
  def load_asset_data
    return false unless super
    begin
      # Update the concordance again after indexing the bam
      update_bioentry_concordance_from_bam
      if(bam && !big_wig)
        self.create_big_wig(:data => bam.create_big_wig)
        big_wig.load if big_wig
      end
      return true
    rescue
      return false
    end
  end

  # use the bam file to update all bioentries assigning external id's from the bam (internal load order vs bam file order)
  # Now using bioentry sequence name method instead bioentry accession column
  # TODO: refact this method to add comparison logic, check accession and name for matches and only 'autosort' the un-matched
  # This will likely be wrong if accessions are not in order and the bam file uses accession rather than names
  # however ordering by accession can be incorrect if the bam file uses names instead of accessions...
  def update_bioentry_concordance_from_bam
    if bam
      external_ids = bam.target_info.keys.sort
      if external_ids.length >= bioentries_experiments.count
        bioentries_experiments.includes(:bioentry).sort{|a,b|a.bioentry.sequence_name<=>b.bioentry.sequence_name}.each_with_index do |bioentry_experiment,index|
          bioentry_experiment.update_attribute(:sequence_name,external_ids[index])
        end
      end
    end
  end
  
  # stores the maximum value for each bioentry in the join table
  def set_abs_max
    bioentries_experiments.each do |be|
      be.update_attribute(:abs_max, self.max(be.sequence_name)) rescue (logger.info "\n\nError Setting abs_max for experiment: #{self.inspect}\n\n")
    end
  end
  
  # generates tracks for each bioentry
  # creates ReadsTracks if a bam is present otherwise HistogramTracks are created
  def create_tracks
    self.bioentries_experiments.each do |be|
      if(bam)
        reads_tracks.create(:bioentry => be.bioentry) unless reads_tracks.any?{|t| t.bioentry_id == be.bioentry_id}
      else
        histogram_tracks.create(:bioentry => be.bioentry) unless histogram_tracks.any?{|t| t.bioentry_id == be.bioentry_id}
      end
    end
  end
  
  # searches for a read by id and returns alignment data. See bam#find_read for details
  def find_read(read_id, chrom, pos)
    bam.find_read(read_id, chrom, pos)
  end
  # returns histogram data see big_wig#summary_data for details
  def summary_data(start,stop,num,chrom)
    (self.big_wig ? big_wig.summary_data(start,stop,num,chrom).map(&:to_f) : [])
  end
  # returns reads in chromosome range see bam#get_reads
  def get_reads(start, stop, chrom)
    bam.get_reads(start, stop, chrom)
  end
  # returns processed reads as formatted text see bam#get_reads_text
  def get_reads_text(start, stop, chrom,opts)
    bam.get_reads_text(start, stop, chrom,opts)
  end
  # returns the max value stored in the big_wig
  # if a sequence_name is supplied it will return max for that sequence only
  def max(chrom='')
    begin
      if big_wig
        big_wig.max(chrom)
      else
        1
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
    "blocks"
  end

  def single
    self.show_negative == "false" ? "true" : "false"
  end
end