class GcFile < SequenceFile
  def open_bw
    begin
      @err = nil
      @bw ||=Biosql::Ucsc::BigWig.open(data.path)
    rescue => e
      @err = e
      # in case file doesn't exist or is bad format
      @bw = nil
    end
  end
  # Returns data summary from the specified chromosome and region.
  # supported types are [max,min,mean,std,coverage]
  def summary_data(chrom,start,stop,count,opts={})
    return [] unless bw = open_bw
    opts[:type]||='mean'
    bw.summary(chrom.to_s,start,stop,count,opts).tap{
      bw.close
    }
  end
end