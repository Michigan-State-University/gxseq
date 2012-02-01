class ChipChip < Experiment
  has_many :peaks, :foreign_key => "experiment_id"
  has_many :histogram_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  #asset types
  has_one :big_wig, :foreign_key => "experiment_id"
  has_one :wig, :foreign_key => "experiment_id"
  
  after_save :set_abs_max
  
  ##Specialized Methods
  def asset_types
    {"bigWig" => "BigWig", "wig" => "Wig"}
  end  
  
  def load_asset_data
    # check for big_wig; create it
    self.update_attribute(:state,"saving")
    unless(self.big_wig)
      raise StandardError, "No wig found!" unless self.wig
      chr = self.get_chrom_file
      f = wig.data.path+"_bw"
      FileManager.wig_to_bigwig!(wig.data.path, f, chr.path)
      self.big_wig = bw = assets.new(:type => "BigWig", :data => File.open(f))
      bw.save!
      FileUtils.rm(f)
    end
    # compute associated data
    self.update_attribute(:state,"computing")
    compute_peaks
    self.update_attribute(:state,"ready")
  end
  
  def remove_asset_data
    # remove any peaks
    self.peaks.destroy_all
  end
  
  def create_tracks
    self.bioentries_experiments.each do |be|
      histogram_tracks.create(:bioentry => be.bioentry) unless histogram_tracks.any?{|t| t.bioentry_id == be.bioentry_id}
    end
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

  # def wig_header
  #   "track type=wiggle_0\nvariableStep chrom=#{sequence_name || bioentry.name} span=1"
  # end

  ##Class Specific
  def max(chrom='')
    begin
      big_wig.max(chrom)
    rescue
      1
    end
  end

  def set_abs_max
    bioentries_experiments.each do |be|
      be.update_attribute(:abs_max, self.max(be.sequence_name)) rescue (logger.info "\n\nError Setting abs_max for experiment: #{self.inspect}\n\n")
    end
  end

  def create_smoothed_experiment(exp_hsh={}, smooth_hsh={})
    puts "---Creating new Smoothed experiment #{smooth_hsh.inspect} #{Time.now}"
    begin
      ChipChip.transaction do
        new_exp = self.clone(exp_hsh)
        if(new_exp.valid?)
          smooth_hsh[:filename]=new_exp.name.gsub(' ','_').downcase
          f = self.big_wig.get_smoothed_data(smooth_hsh)
          new_exp.assets << Asset.new(:type => "BigWig",:data => f)
          new_exp.save!
          puts "Done creating new smoothed experiment: #{exp_hsh[:name]} #{Time.now}"
        else
          puts "Smoothing error: Invalid experiment received #{Time.now}"
        end
      end
    rescue Exception => e
      puts "Error creating smoothed bigwig\n#{$!}\n#{e.backtrace}\n"
    end
  end
  handle_asynchronously :create_smoothed_experiment
  
  def extract_peaks
    begin
      big_wig.extract_peaks
    rescue
      e = "**Error extracting peak information:\n#{$!}"
      puts e
      logger.info "\n\n#{e}\n\n"
    end
  end
  
  def compute_peaks
    self.update_attribute(:state,"computing")
    bioentries_experiments.each do |be|
      puts "Removing stored peaks for #{be.sequence_name}"
      self.peaks.with_bioentry(be.bioentry_id).destroy_all
      puts "Computing peaks for #{be.sequence_name}"
      new_peaks = big_wig.extract_peaks(be.sequence_name)
      set_peaks(be.bioentry_id, new_peaks)
    end
    self.update_attribute(:state,"ready")
    puts "Done Computing peaks #{Time.now}"
    return self.peaks.count
  end
  
  def set_peaks(bioentry_id, data)
    #set peaks to the values in array data
    #format: [start,end,value,pos]
    puts "saving #{data.size} peaks"
    return false if !data.kind_of?(Array)
    bc=Bioentry.find(bioentry_id).length
    begin
      Experiment.transaction do
        #looks good load them
        data.each do |d|
          unless (d.size == 4 && d[0].kind_of?(Integer) && d[1].kind_of?(Integer) && d[2].respond_to?("to_i") && (d[2].to_i > 0)  && d[3].kind_of?(Integer))
            e= "Error invalid format #{d.inspect}";puts e;logger.info "\n\n#{e}\n\n";next
          end
          unless d[0]<d[1]
            e= "Error start > end";puts e;logger.info "\n\n#{e}\n\n";next
          end
          unless (d[0]>0 && d[3] < bc) && (d[0]<=d[3] &&d[3]<=d[1])
            e= "Error peak out of bounds";puts e;logger.info "\n\n#{e}\n\n";next
          end
          p = self.peaks.build(
          :start_pos => d[0],
          :end_pos => d[1],
          :val => d[2],
          :pos => d[3],
          :bioentry_id => bioentry_id
          )
          p.save!
        end
      end
    rescue
      e = "**Error loading peak data:\n#{$!}"
      puts e;logger.info "\n\n#{e}\n\n"
      return false
    end
  end
  
end


# == Schema Information
#
# Table name: experiments
#
#  id          :integer(38)     not null, primary key
#  bioentry_id :integer(38)
#  user_id     :integer(38)
#  name        :string(255)
#  type        :string(255)
#  description :string(255)
#  file_name   :string(255)
#  a_op        :string(255)
#  b_op        :string(255)
#  mid_op      :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  creator_id  :integer(38)
#  updater_id  :integer(38)
#  abs_max     :string(255)
#

