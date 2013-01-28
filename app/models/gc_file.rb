class GcFile < SequenceFile
  def open_bw
    begin
      @err = nil
      @bw ||=Bio::Ucsc::BigWig.open(data.path)
    rescue => e
      @err = e
      # in case file doesn't exist or is bad format
      @bw = nil
    end
  end
  # Returns data summary from the specified chromosome and region.
  # supported types are [max,min,mean,std,coverage]
  def summary_data(start,stop,count,type="mean",opts={})
    # TODO: convert all 'type' references to opts[:type] for bigwig summary
    return [] unless open_bw
    opts[:type]||=type
    #TODO: refactor use taxon_version for lookup, need to be supplied chrom or bioentry
    #TODO: bug fix for bio::ucsc  convert chrom to_s to avoid errors
    open_bw.summary(bioentry_id.to_s,start,stop,count,opts)
  end
end