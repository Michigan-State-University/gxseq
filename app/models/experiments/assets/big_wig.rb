class BigWig < Asset
  def check_data_format
    #self.validated = true
    if (self.data.queued_for_write[:original])
      data_path = self.data.queued_for_write[:original].path
    else
      data_path = data.path
    end
    logger.info "\n\n\n\n#{CMD_PATH}validateFiles -type=bigWig '#{data_path}' -chromInfo=#{experiment.get_chrom_file.path}\n\n\n\n"
    stdin, stdout, stderr = Open3.popen3("#{CMD_PATH}validateFiles -type=bigWig '#{data_path}' -chromInfo=#{experiment.get_chrom_file.path}")
    stderr.each do |e|
      e = e.chomp.gsub(data_path,"").gsub("\t",'')
      self.warnings << e unless (e=~/Abort/ or e.gsub(/\s/, '').blank?)
    end
  end

  def info(opts="")
    FileManager.bigwig_info(data.path,opts)
  end

  def bases_covered
    info("| grep basesCovered | cut -f 2 -d ' '").gsub(/,/,"").to_i
  end

  def min(chrom='')
    stat('min',chrom)
  end

  def max(chrom='')
    stat('max',chrom)
  end

  def mean(chrom='')
    stat('mean',chrom)
  end

  def standard_deviation(chrom='')
    stat('std',chrom)
  end

  def chrom_length(chrom)
    FileManager.bigwig_info(data.path, " -chroms | grep #{chrom} | cut -f 3 -d ' '").to_i
  end

  def stat(type,chrom='')
    if(chrom.empty?)
      a = info("| grep #{type} | cut -f 2 -d ' '").to_f
    else
      total = chrom_length(chrom)
      if(total and total.is_a?(Integer) and total > 0)
        a = summary_data(0,total,1,chrom,type)[0].to_f
      end
    end
    return a || 0
  end
  # def get_base_counts(start,stop,bases,chrom,type="max")
  #   base_counts = `#{CMD_PATH}bigWigSummary -type=#{type} '#{data.path}' #{chrom} #{start} #{stop} #{(stop-start)/bases}`.chomp.split("\t")
  # end

  def summary_data(start,stop,count,chrom,type="max")
    base_counts = `#{CMD_PATH}bigWigSummary -type=#{type} '#{data.path}' #{chrom} #{start} #{stop} #{count}`.chomp.split("\t")
  end

  def get_smoothed_data(hsh={})
    #setup options
    {:window => 250,:type => 'avg'}.merge!(hsh.delete_if{|k,v| v.blank?})
    hsh[:file_path] ||= Tempfile.new("#{hsh[:filename] || self.experiment.name+'_smoothed'}").path
    #run smoothing tool
    begin
      stdin, stdout, stderr = Open3.popen3("#{CMD_PATH}bigWigSmooth #{data.path}  '#{hsh[:file_path]}' -type=#{hsh[:type]} -window=#{hsh[:window]} #{hsh[:cutoff].blank? ? '' : "-cutoff=#{hsh[:cutoff]}"}")
      stderr.each do |e|
        raise e unless e.chomp.blank?
      end
    rescue
      puts "Error running bigwig smooth\n#{$!}"
      logger.info "\nError running bigwig smooth\n#{$!}\n"
    end

    #return file handle
    begin
      return File.open(hsh[:file_path])
    rescue
      puts "error opening bigwig smooth output\n#{$!}"
      logger.info "\nerror opening bigwig smooth output\n#{$!}\n"
    end

  end

  def extract_peaks(chrom,opt={})
    #naive simple peak detection using constant cutoff, window defines data amount pulled from chipseq for each loop #TODO refactor/optimize
    #~ 1min / 10mb
    window = 1000000 #amount of data to request from bigwig in each chunk
    #values=[]
    above_cutoff=false
    peaks=[]
    peak_count=0
    peak_max=opt[:peak_max] || 500
    bc = chrom_length(chrom)
    opt[:error] ||= 0.00001
    opt[:z] ||= 3
    first = true
    pos=0
    puts "Extracting peak data from chrom=(#{chrom}) #{Time.now}"
    cutoff = (summary_data(0,bc,1,chrom,'std')[0].to_f*opt[:z])+summary_data(0,bc,1,chrom,'mean')[0].to_f #z std_deviations from the mean
    puts "Cutoff set to: #{cutoff.inspect}"
    puts "Identifying peak ranges"
    while(pos<((bc / window)+1) )
      values=[]
      offset = (pos*window)
      summary_data(offset,offset+window,window,chrom,'max').each do |v|
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
      puts "Completed: #{sprintf "%05.2f",(((values.size+offset)/bc.to_f)*100.00)}% \t Identified #{peaks.size} total peaks"
      pos +=1

      if(peak_count > peak_max)
        #too many peaks start over and raise the sensitivity
        opt[:z]*=2
        cutoff = (summary_data(0,bc,1,chrom,'std')[0].to_f*opt[:z])+summary_data(0,bc,1,chrom,'mean')[0].to_f
        peak_count=0
        peaks = []
        pos = 0
        first = true
        puts "\nToo many peaks identified (max #{peak_max}) trying again ...\n"
      end
    end

    if(above_cutoff) #peak at end of dataset
      peaks[peak_count]<<bc
      peak_count += 1
    end
    puts "\n#{peak_count} peaks identified"

    #begin summit calculations (tip of peak range)  #TODO add peak width and iterate to refine possible plataeu peaks
    puts "locating peak summits #{Time.now} "
    peaks.each_with_index do |p, i| 
      peak_maximum = summary_data(p[0],p[1],1,chrom,'max')[0].to_f
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
    summary_data(x1,x2,(x2-x1),chrom,'max').each_with_index do |val,i|
      if ( (match-error) <= val.to_f && val.to_f <= (match+error) )
        a << (i+x1)
      end
    end
    return a
  end

end