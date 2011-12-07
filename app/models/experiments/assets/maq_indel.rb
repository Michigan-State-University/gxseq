class MaqIndel < Asset
  def check_data_format
    #only validate once
    self.validated = true
  end

  # parse data file and insert variant records
  def load_data
    @seq_name_lookup||={}
    @seq_lookup||={}
    begin
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
      puts "Error running MaqIndel create_variants:\n#{$!}"
      update_attribute(:state, "error")
      experiment.update_state_from_assets
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
      if(hsh = parse_variant_line(line))
        SequenceVariant.fast_insert(hsh)
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
    
    @seq_name_lookup[col[2]]||=experiment.bioentries_experiments.find_by_sequence_name(col[2])
    # store nil return so we don't continue to look it up
    if @seq_name_lookup[col[2]] == "Null" || @seq_name_lookup[col[2]].nil?
      @seq_name_lookup[col[2]] = "Null"
      puts "warning: Unknown Sequence Found in File:"
      puts "\t'#{col[2]}'"
      return false
    else
      bioentry_id = @seq_name_lookup[col[2]].bioentry_id
      bioentry_seq = (@seq_lookup[bioentry_id.to_s]||=@seq_name_lookup[col[2]].bioentry.biosequence.seq)
    end
    
    #setup ref / alt  sequence
    size = col[6].split(":")[0].to_i
    seq = col[6].split(":")[1]
    pos = col[3].to_i - 1 #convert to zero-based
    if size > 0
      type = "Insertion"
      reference = bioentry_seq[pos].chr
      alt = reference + seq
    elsif size < 0
      type = "Deletion"
      alt = ""
      reference = bioentry_seq[pos,size.abs]
      if(reference != seq)
        puts "warning: parsed Deletion does not equal sequence!: '#{reference}' != '#{seq}'"
        puts "\t#{line}"
        return false
      end
    else
      #size == 0 ? hax!
      puts "warning: found 0 size indel in file!"
      return false
    end
    
    hsh = {
      :type => type,
      :experiment_id => experiment.id,
      :pos => pos,
      :ref => reference,
      :alt => alt,
      :depth => col[5].to_i,
      :qual => -1,
      :bioentry_id => bioentry_id
    }
  end

end