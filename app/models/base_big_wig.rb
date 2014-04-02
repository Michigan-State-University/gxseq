# == Schema Information
#
# Table name: assets
#
#  created_at        :datetime
#  data_content_type :string(255)
#  data_file_name    :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#  sample_id     :integer
#  id                :integer          not null, primary key
#  state             :string(255)      default("pending")
#  type              :string(255)
#  updated_at        :datetime
#

class BaseBigWig < Asset
  def open_bw
    begin
      @err = nil
      Bio::Ucsc::BigWig.open(data.path)
    rescue => e
      @err
      @bw = nil
      return false
    end
  end
  
  def info(opts={})
    return @err.to_s unless bw = open_bw
    bw.info(opts).tap{ bw.close }
  end

  def bases_covered
    return 0 unless bw = open_bw
    bw.bases_covered.tap{ bw.close }
  end

  def min(chrom=nil)
    return 0 unless bw = open_bw
    bw.min(chrom).tap{ bw.close }
  end

  def max(chrom=nil)
    return 0 unless bw = open_bw
    bw.max(chrom).tap{ bw.close }
  end

  def mean(chrom=nil)
    return 0 unless bw = open_bw
    bw.mean(chrom).tap{ bw.close }
  end

  def standard_deviation(chrom=nil)
    return 0 unless bw = open_bw
    bw.std_dev(chrom).tap{ bw.close }
  end

  def chrom_length(chrom)
    return 0 unless bw = open_bw
    bw.chrom_length(chrom).tap{ bw.close }
  end
  # Returns data summary from the specified chromosome and region binned using the type option
  # aggregation type can be [max,min,mean,std,coverage]
  # :start => sequence start position, 1 based, open interval
  # :stop  => sequence end position, 1 based, open interval
  # :count => number of bins to return
  # :opts => options hash:
  # - :type => aggregation type for bins
  def summary_data(start,stop,count,chrom,opts={})
    return [] unless bw = open_bw
    opts[:type]||='max'
    bw.summary(chrom,start,stop,count,opts).tap{ bw.close }
  end
  # smooth this data returning a new file_handle. Calls the C bigWigSmooth utility
  # hash options:
  # - :window => The rolling window size [250]
  # - :cutoff => The inflection cutoff for 'probe' smoothing. Inflection points will be identified above this cutoff.
  # - :type  => The smoothing type:
  # --- 'avg' : rolling window average using window size
  # --- 'probe' : rolling window inflection point count using window size and cutoff
  def get_smoothed_data(opts={})
    window = opts[:window] || 250
    type = opts[:type] || 'avg'
    file_path = Tempfile.new(opts[:filename]||self.sample.name+'_smoothed').path
    cutoff = opts[:cutoff].to_f if type=='probe' unless opts[:cutoff].blank?
    #run smoothing tool
    begin
      bw = open_bw
      bw.smooth(file_path,{:type => type,:window => window,:cutoff => cutoff}).tap{ bw.close }
    rescue
      s = "Error running bigwig smooth\n#{$!}"; puts s ; logger.info s
    end
    #return file handle
    begin
      return File.open(file_path)
    rescue
      s = "error opening bigwig smooth output\n#{$!}"; puts s ; logger.info s
    end
  end
  # Find peaks in the data using a cutoff to identify ranges and inflection points.
  # hash options:
  # - :remove => boolean flag for removing existing peaks [false]
  # - :z => cutoff multiplier. number of standard deviations above the mean [3]
  # - :c => manual cutoff. The actual value used for range start/end. Overrides z if not 0 [0]
  # - :peak_max => total couunt of peaks allowed. If surpassed, z (or c) is multiplied by 2 and the process re-starts [100]
  def extract_peaks(chrom,opt={})
    # window defines data amount pulled from bigwig for each loop
    #~ 1min / 10mb
    window = 1000000 #amount of data to request from bigwig in each chunk
    above_cutoff=false
    peaks=[]
    peak_count=0
    peak_max=opt[:peak_max] || 100
    bc = chrom_length(chrom)
    opt[:error] ||= 0.00001
    opt[:z] ||= 3
    opt[:c] ||= 0
    first = true
    pos=0
    puts "Extracting peak data from chrom=(#{chrom}) #{Time.now}"
    if opt[:c] != 0
      cutoff = opt[:c]
    else
      cutoff = ( standard_deviation(chrom) * opt[:z] ) + mean(chrom)
    end
    puts "Cutoff set to: #{cutoff.inspect}"
    puts "Identifying peak ranges"
    while(pos<((bc / window)+1) )
      values=[]
      offset = (pos*window)
      summary_data(offset,offset+window,window,chrom,{:type => 'max'}).each do |v|
        values <<( v.nil? ? 0 : v.to_f)
      end
      printf "\nWorking on #{offset},#{offset+window}\n"
      #end

      if(values.size == 0 )
        printf "No datapoints found. skipping\n"
        pos +=1
        next
      end

      if(first)
        #test the first point to set starting condition
        above_cutoff = ( values[0] >= cutoff )
        if above_cutoff #peak at beginning of dataset
          peaks << [0]
        end
        first = false
      end

      #loop through each point searching for intersections with cutoff
      values.each_with_index do |val, i|
        d=(val > cutoff )
        if above_cutoff
          unless(d)#peak end
            peaks[peak_count] << i+offset
            above_cutoff = false
            peak_count += 1
            printf "\t\t\tFound peak %i:(%i,%i)\r", peak_count,peaks[peak_count-1][0],peaks[peak_count-1][1]
            percent = ((i+offset)/bc.to_f)*100.00
            printf "Completed: %5.2f%%\r", percent.to_f
          end
        else
          if(d)#peak start
            peaks << [i+offset] 
            above_cutoff = true
          end
        end
      end
      puts "\nCompleted: #{sprintf "%05.2f",(((values.size+offset)/bc.to_f)*100.00)}% \t Identified #{peaks.size} total peaks"
      pos +=1

      if(peak_count > peak_max)
        #too many peaks start over and raise the sensitivity
        opt[:z]*=2
        cutoff = ( standard_deviation(chrom)*opt[:z] )+mean(chrom)
        peak_count=0
        peaks = []
        pos = 0
        first = true
        puts "\nToo many peaks identified (max #{peak_max}) trying again with cutoff=#{cutoff}...\n"
      end
    end

    if(above_cutoff) #peak at end of dataset
      peaks[peak_count]<<bc
      peak_count += 1
    end
    puts "\n#{peak_count} peaks identified"

    #begin summit calculations (tip of peak range)
    puts "locating peak summits #{Time.now} "
    peaks.each_with_index do |p, i| 
      peak_maximum = summary_data(p[0],p[1],1,chrom,{:type => 'max'}).first.to_f || 0
      summit_positions = find_match_in_range(p[0],p[1],peak_maximum,chrom,opt[:error])
      if summit_positions.empty?
        puts "Warning couldn't identify summit in (#{p[0]},#{p[1]})"
        next
      end
      peaks[i]<<peak_maximum
      peaks[i]<<summit_positions[(summit_positions.length/2).to_i] #median location with max value
      percent = ((i+1)/peak_count.to_f)*100.00
      printf "Completed: %5.2f%%\r", percent.to_f
    end
    puts "\nDone #{Time.now}\n"
    return peaks
  end

  def find_match_in_range(x1,x2,match,chrom,error=0.0)
    a = []
    if(x2<x1)
      puts "Warning: reversing input. x1:#{x1}, x2:#{x2} please use x1 < x2"
      t = x1
      x1 = x2
      x2 = t
    end
    summary_data(x1,x2,(x2-x1),chrom,{:type => 'max'}).each_with_index do |val,i|
      if ( (match-error) <= val.to_f && val.to_f <= (match+error) )
        a << (i+x1)
      end
    end
    return a
  end

end
