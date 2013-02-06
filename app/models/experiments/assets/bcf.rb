class Bcf < Asset
  
  def load
    update_attribute(:state, "loading")
    create_index
    update_attribute(:state, "complete")
  end
  
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
      b_struct = Bio::DB::SAM::Tools::Bcf::Bcf1T.new(bcf_p)
      # skip invalid variants
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
      # reservoir sampling
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
      next if only_variants && b_struct[:alt] == b_struct[:ref] || b_struct[:alt] == '.'
      
      # store the variant(s)
      v = Bio::DB::SAM::Variant.new(bcf_p,hdr_p)
      # check gt info
      v1 = {}
      v1[:allele]=1
      v1[:pos]=v.pos
      v1[:dbid]=v.tid
      v1[:ref]=v.ref
      v1[:alt]=v.alt
      v1[:qual]=v.qual
      v1[:id]="1_#{v1[:pos]}_#{v1[:ref]}_#{v1[:alt]}"
      v1[:type]=v.variant_type.downcase
      v1[:v]=v
      if(sample_idx)
        gt = v.geno_fields.find{|g| g.format=='GT'}.data[sample_idx]
        v2 = v1.clone
        if(gt[0]=='0')
          v1[:type] = 'match'
        end        
        v2[:allele] = 2
        v2[:id]="2_#{v1[:pos]}_#{v1[:ref]}_#{v1[:alt]}"
        # split heterozygous
        # if(split_hets && !only_variants)          
        #   if((gt[0]!='0'&&gt[2]=='0')||(gt[0]=='0'&&gt[2]!='0'))
        if gt[2]=='0'
          v2[:type]='match'
        end
        #   end
        # end
      end
      
      variants[idx] = [v1,v2]
      cnt +=1
    end    
    bcf.fetch_with_function_raw(seq,start,stop,fetch_function)
    bcf.close
    return variants.flatten.compact
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
