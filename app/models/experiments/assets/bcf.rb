class Bcf < Asset
  
  def open_bcf
    return Bio::DB::SAM::Bcf.new(data.path)
  end
  
  def create_index
    #opening the bcf checks and creates index automatically
    b = open_bcf
    b.close
  end
  
  def get_data(seq,start,stop,opts={})
    bcf = open_bcf
    sample_idx = samples.find_index(opts[:sample])
    split_hets = opts[:split_hets]
    only_variants = opts[:only_variants]
    limit = opts[:limit]
    variants = []
    random = Random.new(1024)
    idx = 0
    cnt = 0
    # fetch function - expects pointers to Bcf1T and BcfHdrT
    # limits reads using a reservoir sampling algorithm
    fetch_function = lambda do |bcf_p, hdr_p|
      if limit 
        if variants.size < limit
          idx = cnt
        else
          r = random.rand(cnt+1)
          if(r < limit)
            idx = r
          else
            cnt+=1
            next
          end
        end
      else
        idx = cnt
      end
        #break if limit && variants.size >= limit
      b_struct = Bio::DB::SAM::Tools::Bcf::Bcf1T.new(bcf_p)
      if(b_struct[:n_gi] > 0)
        if(sample_idx)
          # skip sample with no data
          next if (b_struct[:gi].get_pointer(8).get_uint8(sample_idx) >> 7 & 1) > 0
        end
        if(only_variants)
          # test all gt tags. Need non-zero for alternate match
          next if b_struct[:gi].get_pointer(8).read_array_of_uint8(b_struct[:n_smpl]).collect{|g| g & 63}.uniq == [0]
        end
      end
      # store the variant(s)
      v = Bio::DB::SAM::Variant.new(bcf_p,hdr_p)
      # check gt info
      if(sample_idx)
        gt = v.geno_fields.find{|g| g.format=='GT'}.data[sample_idx]
        if([['0','/','0'],['0','|','0']].include?(gt))
          v.variant_type = 'Match'
        end
        # split heterozygous
        if(split_hets && !only_variants)          
          if((gt[0]!='0'&&gt[2]=='0')||(gt[0]=='0'&&gt[2]!='0'))
            v2 = Bio::DB::SAM::Variant.new(bcf_p,hdr_p)
            v2.variant_type='Match'
            v2.alt = v2.ref
            variants[idx]=v2
            idx +=1
            cnt +=1
          end
        end
      end
      variants[idx] =  v
      cnt +=1
    end    
    bcf.fetch_with_function_raw(seq,start,stop,fetch_function)
    bcf.close
    return variants
  end
  
  def sequence
    b = open_bcf
    seq = b.sequence
    b.close
    return seq
  end
  
  def samples
    b = open_bcf
    samples = b.samples
    b.close
    return samples
  end
  
  def text
    b = open_bcf
    b.txt.tap{
      b.close
    }
  end
end