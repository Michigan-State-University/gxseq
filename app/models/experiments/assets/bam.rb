class Bam < Asset
  require 'strscan'
  
  def check_data_format
  end
  
  def open_bam    
    Bio::DB::Sam.new(:bam=>data.path,:fasta => "").tap{|b|b.open}
  end
  
  # NOTE does NOT work with delayed_job background tasks
  def index_stats
    bam = open_bam
    bam.index_stats.tap{
      bam.close
    }    
  end
  
  def flagstat
    bam = open_bam
    bam.flagstat.tap{
      bam.close
    }
  end
  
  def target_info
    bam = open_bam
    bam.target_info.tap{
      bam.close
    }
  end
  
  def get_reads(left,right,seq)
    bam = open_bam
    bam.fetch(seq,left,right).tap{
      bam.close
    }
  end
  
  def find_read(read_id, chrom, pos)
    bam = open_bam
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
  
  def get_reads_text(left,right,seq,opts)
    
    bam = open_bam
    
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
            while(val = scanner.scan(md_reg))
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
      strand = (set_item[0][1].to_i & 0x0010 > 0) ? '+' : '-'   # sam_data bit flag for strand -- 0x10 SEQ being reverse complemented
      
      reads << "[\"#{seq_name}\",#{set_item[0][3]},#{width},\"#{strand}\",\"#{seq}\"],"
    end

    bam.close
    
    return [reads.chop, count, subset.size]
  end
  
  def create_big_wig(opts={})
    bam = open_bam
    puts "----"
    puts "#{Time.now} Creating BigWig File"
    # convert output to bed format
    com = opts[:com] || '\' | awk \'{print $1, $2-1, $2, $4}'
    # clean any old tempfiles
    remove_temp_files
    # create new tempfiles
    bed = File.new(data.path+".bed_tmp", "w")
    bed_sort = File.new(data.path+".bed_srt_tmp", "w")
    bw = File.new(data.path+".bw_tmp", "w")
    chr = File.new(data.path+".chrom.sizes","w")
    
    if target_info.length == 0
      raise "File Error: No items found in index"
    end
    target_info.each do |accession,hsh|
      next unless( hsh[:length] && hsh[:length]>0)
      length = hsh[:length]
      puts "--Working on #{accession} - Length: #{hsh[:length]}"
      bam.mpileup_text({:r => "#{accession}"},bed.path,com)
      # write chrom.sizes data
      chr.puts "#{accession} #{length}"
    end
    
    chr.flush
    bed.flush
    bam.close
    
    # puts "--Sorting output"
    #`sort -k1,1 -k2,2n '#{bed.path}' > '#{bed_sort.path}'`
    puts "--Converting"
    FileManager.bedgraph_to_bigwig(bed.path, bw.path, chr.path)
    puts "#{Time.now} Done"
    puts "----"
    File.open(data.path+".bw_tmp", "r")
  end
  
  def remove_temp_files
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.full_filename) && f.match(/\.bw_tmp$|\.bed_tmp$|\.bed_srt_tmp$|\.chrom\.sizes$/) )
    end
  end
  
  def create_index
    bam = open_bam
    puts "#{Time.now} Creating Bam Index"
    bam.load_index
    bam.close
  end
  
  def index_file
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      if( f.match(self.full_filename) && f.match('bai') )
        return File.open(d.path+"/"+f)
      end
    end
    return nil
  end
  
  def destroy_index
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.full_filename) && f.match(/\.bai$/) )
    end
  end
  
  
end