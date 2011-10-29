class GcFile < SequenceFile
  def summary_data(start,stop,count,type="mean")
    begin
      base_counts = `#{CMD_PATH}bigWigSummary -type=#{type} #{data.path} #{bioentry_id} #{start} #{stop} #{count}`.chomp.split("\t")
    rescue
      []
    end
  end
end