# == Schema Information
#
# Table name: sequence_files
#
#  assembly_id       :integer
#  created_at        :datetime
#  data_content_type :string(255)
#  data_file_name    :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#  id                :integer          not null, primary key
#  type              :string(255)
#  updated_at        :datetime
#

class GcFile < SequenceFile
  def open_bw
    begin
      @err = nil
      @bw ||=Bio::Ucsc::BigWig.open(data_path)
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
