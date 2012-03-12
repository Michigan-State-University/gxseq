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
    bcf.get_data(seq,start,stop,opts).tap{
      bcf.close
    }
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