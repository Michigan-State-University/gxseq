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

class Bam < Asset
  require 'strscan'
  
  ## Asset Generic Methods
  
  # generates an index and updates state
  def load
    update_attribute(:state, "loading")
    create_index
    remove_temp_files
    update_attribute(:state, "complete")
  end
  
  # removes any generated data and updates state
  def unload
    remove_temp_files
    destroy_index
    update_attribute(:state, "pending")
  end
  
  ## Instance Methods
  
  def open_bam
    begin
      return Bio::DB::Sam.new(:bam=>data.path,:fasta => "").tap{|b|b.open}
    rescue => e
      puts "Error Opening Bam file: #{e}"
      return false
    end
  end

  # returns hash of index data
  # { "sequence_1"  => {:length => 1000, :unmapped_reads => 10, :mapped_reads => 1000}, ... }
  def index_stats
    return [] unless bam = open_bam
    bam.index_stats.tap{
      bam.close
    }
  end
  
  def flagstat
    return nil unless bam = open_bam
    bam.flagstat.tap{
      bam.close
    }
  end
  
  def target_info
    return [] unless bam = open_bam
    bam.target_info.tap{
      bam.close
    }
  end
  # counts the total number of mapped reads in the bam
  def total_mapped_reads
    index_stats.inject(0){|sum,info| sum+=info[1][:mapped_reads]}
  end
  # counts the total number of un-mapped reads in the bam
  def total_unmapped_reads
    index_stats.inject(0){|sum,info| sum+=info[1][:unmapped_reads]}
  end
  # returns reads overlapping the supplied region
  def get_reads(left,right,seq)
    return [] unless bam = open_bam
    bam.fetch(seq,left,right).tap{
      bam.close
    }
  end
  # returns a read for display containing all of the read details
  #   :id => read id,
  #   :flag => SAM flag,
  #   :pos => start,
  #   :mapq => mapping quality,
  #   :cigar => cigar format,
  #   :mate_ref => reference name of paired mate,
  #   :mate_pos => position of paired mate,
  #   :tlen => template length,
  #   :seq => nucleotide sequence,
  #   :qual => read quality,
  #   :tags => additional flags,
  #   :qlen => qlen.to_i,
  #   :calend => calend.to_i,
  def find_read(read_id, chrom, pos)
    return [] unless bam = open_bam
    read = nil
    qlen = nil
    calend = nil
    fetchFunc = Proc.new do |bam_alignment,header|
      data = Bio::DB::SAM::Tools.bam_format1(header,bam_alignment)      
      sam_data = data.read_string.split("\t")
      LibC.free data
      if(sam_data[0]==read_id)
        # parse extra information
        al = Bio::DB::SAM::Tools::Bam1T.new(bam_alignment)
        core = al[:core]
        cigar = al[:data][core[:l_qname]]
        calend = Bio::DB::SAM::Tools.bam_calend(core,cigar)
        qlen = Bio::DB::SAM::Tools.bam_cigar2qlen(core,cigar)
        read = sam_data
        -1
      else
        0
      end
    end
    
    bam.fetch_with_function_raw(chrom,pos,pos+1,fetchFunc)
    bam.close
    if(read)
      h={
        :id => read_id,
        :flag => read[1],        
        :pos => read[3].to_i,
        :mapq => read[4].to_i,
        :cigar => read[5],
        :mate_ref => read[6],
        :mate_pos => read[7].to_i,
        :tlen => read[8].to_i,
        :seq => read[9],
        :qual => read[10],
        :tags => Hash[*((read[11,read.length-11]).collect{|t| a = t.split(":"); [a[0]+":"+a[1],a[2]]}.flatten)],
        :qlen => qlen.to_i,
        :calend => calend.to_i,
        :sam  => read
      }
      return h
    end
    nil
  end
  # returns text array of read data for items overlapping the supplied region
  # :format  =>  [name, start, length, strand, sequence]
  def get_reads_text(left,right,seq,opts)
    
    return [] unless bam = open_bam
    
    read_limit = opts[:read_limit] || 10000
    include_seq = opts[:include_seq]
    reads_forward = ""
    reads_reverse = ""
    reads = ""
    skipped_reads = 0
    subset = []
    depth=[]
    cur_pos = 0
    pos_depth = 0
    count = 0
    random = Random.new(1024) # the seed must remain constant
    
    # process the sampled reads
    process_alignment = Proc.new do |bam_alignment,header|
      # convert to sam format
      # Col Field   Description
      # 1   QNAME   Query template/pair NAME
      # 2   FLAG    bitwise FLAG
      # 3   RNAME   Reference sequence NAME
      # 4   POS     1-based leftmost POSition/coordinate of clipped sequence
      # 5   MAPQ    MAPping Quality (Phred-scaled)
      # 6   CIAGR   extended CIGAR string
      # 7   MRNM    Mate Reference sequence NaMe (‘=’ if same as RNAME)
      # 8   MPOS    1-based Mate POSistion
      # 9   TLEN    inferred Template LENgth (insert size)
      # 10  SEQ     query SEQuence on the same strand as the reference
      # 11  QUAL    query QUALity (ASCII-33 gives the Phred base quality)
      # 12+ OPT     variable OPTional fields in the format TAG:VTYPE:VALUE
      data = Bio::DB::SAM::Tools.bam_format1(header,bam_alignment)      
      sam_data = data.read_string.split("\t")
      # remove the C reference to sam string
      LibC.free data
      
      # parse extra information
      al = Bio::DB::SAM::Tools::Bam1T.new(bam_alignment)
      core = al[:core]
      cigar = al[:data][core[:l_qname]]
      calend = Bio::DB::SAM::Tools.bam_calend(core,cigar)
      qlen = Bio::DB::SAM::Tools.bam_cigar2qlen(core,cigar)
      [sam_data,qlen,calend]
    end
    
    # fetch each read and apply reservoir sampling
    fetchFunc = Proc.new do |bam_alignment,header|
      if(count < read_limit)        
        subset << process_alignment.call(bam_alignment,header)
      else
        r = random.rand(count+1)
        if(r < read_limit)
          subset[r] = process_alignment.call(bam_alignment,header)
        end
      end
      count +=1
      0
    end
    
    # Run the C routine
    bam.fetch_with_function_raw(seq,left,right,fetchFunc)
    
    cnt_reg = /\d+/
    op_reg = /\D/
    md_reg = /\d+|\D+/
    # process the reads array
    subset.each do |set_item|      
      seq,op = "",""
      cnt,idx = 0,0
      if(include_seq)
        seq = set_item[0][9].upcase
        # interpolate cigar data
        # Matches are upper case, mismatches lower
        gaps = []
        scanner = StringScanner.new(set_item[0][5])
        while( cnt = scanner.scan(cnt_reg))
          cnt = cnt.to_i
          op = scanner.scan(op_reg)
          case op
          when "M","="# Match
            idx+=cnt
          when "I","S","H" #Soft and hard clipping are removed, may need update
            seq.slice!(idx,cnt)
          when "D"
            seq.insert(idx,"D"*cnt)
          when "N"
            seq.insert(idx,"-"*cnt)
            # track the gaps for later
            gaps << "[\"read_gap\",#{idx},#{cnt}]"
            idx+=cnt
          when "X"
            seq.insert(idx,seq.slice!(idx,cnt).downcase)
            idx+=cnt
          end
        end
        # parse tags
        idx=0
        11.upto set_item[0].length-1 do |i|
          case set_item[0][i].split(":")[0]
          when 'MD'
            md = set_item[0][i].split(":")[2]
            scanner = StringScanner.new(md)
            while((val = scanner.scan(md_reg)) && idx < seq.length)
              if(val.match(cnt_reg))
                # match - move on
                idx+=val.to_i
              else
                if val =~ /\^/
                  # deletion - handled by cigar
                  idx+=val.length-1
                else
                  # mismatch - replace with downcase
                  seq.insert(idx,seq.slice!(idx,val.length).downcase)
                  idx+=val.length
                end
              end
            end
            
          end
        end
        
      end
      
      # build return text  [name, start, length, strand, sequence]
      seq_name = set_item[0][0]                                 # sam_data: read name
      start = set_item[0][3].to_i                               # sam_data: 1-based mapping position
      width = (set_item[2]-start)+1                             # inclusive width (calend - pos) + 1
      
      # Sam data FLAG field bits
      # 0x0001  p the read is paired in sequencing
      # 0x0002  P the read is mapped in a proper pair
      # 0x0004  u the query sequence itself is unmapped
      # 0x0008  U the mate is unmapped
      # 0x0010  r strand of the query (1 for reverse)
      # 0x0020  R strand of the mate
      # 0x0040  1 the read is the first read in a pair
      # 0x0080  2 the read is the second read in a pair
      # 0x0100  s the alignment is not primary
      # 0x0200  f the read fails platform/vendor quality checks
      # 0x0400  d the read is either a PCR or an optical duplicate
      
      # Check bit flags for orientation
      paired = (set_item[0][1].to_i & 0x1 > 0)
      # mapped_pair = (set_item[0][1].to_i & 0x2 > 0)
      seq_reversed = (set_item[0][1].to_i & 0x10 > 0)
      mate_reversed = (set_item[0][1].to_i & 0x20 > 0)
      first_read = (set_item[0][1].to_i & 0x40 > 0)
      second_read = (set_item[0][1].to_i & 0x80 > 0)
      # Get strand. The second read on paired sequence will be in reversed orientation
      if(paired)
        if(first_read)
          strand = seq_reversed ? '-' : '+'
        elsif(second_read)
          strand = mate_reversed ? '2-' : '2+'
        end
      else
        strand = seq_reversed ? '-' : '+'
      end
      reads << "[\"#{seq_name}\",#{start},#{width},\"#{strand}\",\"#{seq}\",[#{gaps.join(',')}]],"
    end

    bam.close
    
    return [reads.chop, count, subset.size]
  end
  
  def create_big_wig(opts={})
    strand = false
    strand = '+' if opts[:strand]== '+'
    strand = '-' if opts[:strand]== '-'
    puts "----"
    puts "#{Time.now} Creating BigWig File"
    # check data
    unless APP_CONFIG[:bedtools_path]
      puts "Aborting: No Bedtools Path specified"
      return false
    end
    unless bam = open_bam
      puts "Aborting: Bam could not be opened"
      return false
    end
    if target_info.length == 0
      puts "Aborting: No items found in index"
      return false
    end
    # clean any old tempfiles
    remove_temp_files
    # create new tempfiles
    bamt_path = data.path+".bamt_tmp"
    bam1 = File.new(data.path+".bam1_tmp","w")
    bam2 = File.new(data.path+".bam2_tmp","w")
    bed = File.new(data.path+".bed_tmp", "w")
    bed_sort = File.new(data.path+".bed_srt_tmp", "w")
    bw = File.new(data.path+".bw_tmp", "w")
    chr = File.new(data.path+".chrom.sizes","w")
    # write chrom.sizes data
    target_info.each do |accession,hsh|
      next unless( hsh[:length] && hsh[:length]>0)
      length = hsh[:length]
      chr.puts "#{accession} #{length}"
    end
    chr.flush
    # Create the bedGraph
    puts "--Running Bedtools genomeCoverageBed -split -bg;"
    samtools = Bio::DB::Sam.binary_path
    if(strand=='+')
      puts "--- strand: '+'  samtools view -f 99"
      `#{samtools} view -bf 99 #{self.data.path} > #{bam1.path}`
      puts "--- strand: '+'  samtools view -f 147"
      `#{samtools} view -bf 147 #{self.data.path} > #{bam2.path}`
    elsif(strand=='-')
      puts "--- strand: '-'  samtools view -f 83"
      `#{samtools} view -bf 83 #{self.data.path} > #{bam1.path}`
      puts "--- strand: '-'  samtools view -f 163"
      `#{samtools} view -bf 163 #{self.data.path} > #{bam2.path}`
    end
    if(strand)
      # merge strand specific bams
      puts "--- Merging files"
      `#{samtools} merge #{bamt_path} #{bam1.path} #{bam2.path}`
      `#{APP_CONFIG[:bedtools_path]}/genomeCoverageBed -split -bg -ibam #{bamt_path} -g #{chr.path} > #{bed.path}`
    else
      `#{APP_CONFIG[:bedtools_path]}/genomeCoverageBed -split -bg -ibam #{self.data.path} -g #{chr.path} > #{bed.path}`
    end
    bed.flush
    bam.close
    
    # puts "--Sorting output"
    #`sort -k1,1 -k2,2n '#{bed.path}' > '#{bed_sort.path}'`
    puts "--Converting"
    FileManager.bedgraph_to_bigwig(bed.path, bw.path, chr.path)
    puts "#{Time.now} Done"
    puts "----"
    # return the new file 
    return File.open(data.path+".bw_tmp", "r")
  end
  
  def remove_temp_files
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.filename) && f.match(/\.bamt_tmp$|\.bam1_tmp$|\.bam2_tmp$|\.bw_tmp$|\.bed_tmp$|\.bed_srt_tmp$|\.chrom\.sizes$/) )
    end
  end
  
  def create_index
    puts "#{Time.now} Creating Bam Index"
    return false unless bam = open_bam
    bam.load_index
    bam.close
  end
  
  def index_file
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      if( f.match(self.filename) && f.match('bai') )
        return File.open(d.path+"/"+f)
      end
    end
    return nil
  end
  
  def destroy_index
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.filename) && f.match(/\.bai$/) )
    end
  end
  
  
end
