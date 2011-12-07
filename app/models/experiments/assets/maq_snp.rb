class MaqSnp < Asset
  def check_data_format
    #only validate once
    self.validated = true
  end
  
  # parse data file and insert variant records
  def load_data
    begin
      @seq_name_lookup||={}
      update_attribute(:state, "loading")
      experiment.update_state_from_assets
      e = parse_and_create_variants
      if(e==0)
        update_attribute(:state, "complete")
      else
        update_attribute(:state, "#{e} warning#{e > 1 ? 's': ''}")
      end
      experiment.update_state_from_assets
    rescue
      logger.info "\n\nError running MaqSnp create_variants:\n\n#{$!}\n"
      puts "\n\nError running MaqSnp create_variants:\n\n#{$!}\n"
      update_attribute(:state, "error")
      return false
    end
    return true
  end
  handle_asynchronously :load_data
  
  def parse_and_create_variants
    errors = 0
    if self.new_record?
      f = self.data.queued_for_write[:original]
    else
      f = File.open(self.data.path)
    end
    header = f.readline
    line_count = `wc -l #{self.data.path}`.split[0].to_i
    count=0
    part = (line_count / 10).to_i
    f.each do |line|
      count+=1
      if(hsh_array = parse_variant_line(line))      
        hsh_array.each{|hsh| SequenceVariant.fast_insert(hsh) }
      else
        errors +=1
      end
      if(count % part == 0)
        puts "loading..#{((count/line_count.to_f)*100).ceil}%"
      end
    end
    return errors
  end
  
  def parse_variant_line(line)
    col = line.split("\t")
    a = []
    @seq_name_lookup[col[0]]||=experiment.bioentries_experiments.find_by_sequence_name(col[0])
    # store nil return so we don't continue to look it up
    if @seq_name_lookup[col[0]] == "Null" || @seq_name_lookup[col[0]].nil?
      @seq_name_lookup[col[0]] = "Null"
      puts "warning: Unknown Sequence Found in File:"
      puts "\t'#{col[0]}'"
      return false
    else
      bioentry_id = @seq_name_lookup[col[0]].bioentry_id
    end
    
    #use iub code to retrieve actual base for SNP alleles
    SequenceVariant::IUB_CODE[col[12]].each do |iub_base|
      depth = nil
      if(iub_base == col[13].split(":")[0])
        depth = col[13].split(":")[1]
      elsif(iub_base == col[14].split(":")[0])
        depth = col[14].split(":")[1]
      end
      hsh = {
        :type => "Snp",
        :experiment_id => experiment.id,
        :pos => col[1],
        :ref => col[5],
        :alt => iub_base,
        :depth => depth,
        :qual => (col[9]),
        :bioentry_id => bioentry_id
      }
      a<<hsh
    end
    return a
  end
  
end