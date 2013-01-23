class RnaSeq < Experiment
  has_many :reads_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  has_many :feature_counts, :foreign_key => "experiment_id", :dependent => :destroy
  has_one :bam, :foreign_key => "experiment_id"
  has_one :big_wig, :foreign_key => "experiment_id"
  after_save :update_bioentry_concordance_from_bam
  smoothable
  
  def asset_types
    {"Bam" => "Bam","BigWig" => "BigWig"}
  end
  
  def load_asset_data
    puts "Loading asset data #{Time.now}"
    begin
      if(bam)
        bam.update_attribute(:state, "loading")
        update_state_from_assets
        bam.create_index
        self.create_big_wig(:data => bam.create_big_wig)
        bam.remove_temp_files
        update_bioentry_concordance_from_bam
        big_wig.update_attribute(:state, "complete")
        bam.update_attribute(:state, "complete")
        update_state_from_assets
      else
        puts "No bam file found!"
        update_attribute(:state, "error")
      end
    rescue
      puts "Error running RNA-Seq load_assets:\n#{$!}"
      update_attribute(:state, "error")
    end
  end
  
  def remove_asset_data
    puts "Removing all asset data #{Time.now}"
    begin
      bam.remove_temp_files if bam
      bam.destroy_index if bam
    rescue
      puts "Error running RNA-Seq remove asset data:\n#{$!}"
    end
  end
  # use the bam file to update all bioentries assigning external id's from the bam (internal load order vs bam file order)
  def update_bioentry_concordance_from_bam
    if bam
      external_ids = bam.target_info.keys
      if external_ids.length >= bioentries_experiments.count
        bioentries_experiments.order('id asc').each_with_index do |bioentry_experiment,index|
          bioentry_experiment.update_attribute(:sequence_name,external_ids[index])
        end
      end
    end
  end
  
  def create_tracks
    self.bioentries_experiments.each do |be|
      reads_tracks.create(:bioentry => be.bioentry) unless reads_tracks.any?{|t| t.bioentry_id == be.bioentry_id}
    end
  end
  
  def summary_data(start,stop,num,chrom)
    (self.big_wig ? big_wig.summary_data(start,stop,num,chrom).map(&:to_f) : [])
  end
  
  def get_reads(start, stop, chrom)
    bam.get_reads(start, stop, chrom)
  end
  
  def get_reads_text(start, stop, chrom,opts)
    bam.get_reads_text(start, stop, chrom,opts)
  end
  
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
  
  def set_abs_max
    bioentries_experiments.each do |be|
      be.update_attribute(:abs_max, self.max(be.sequence_name)) rescue (logger.info "\n\nError Setting abs_max for experiment: #{self.inspect}\n\n")
    end
  end
  
  ##Track Config
  def iconCls
    "blocks"
  end

  def single
    self.show_negative == "false" ? "true" : "false"
  end
  
  def find_read(read_id, chrom, pos)
    bam.find_read(read_id, chrom, pos)
  end
end