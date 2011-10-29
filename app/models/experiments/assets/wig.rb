class Wig < Asset
  def check_data_format
    #only validate once
    self.validated = true
    file_data = FileManager.parse(self.data.queued_for_write[:original], {:format => self.class.name})
    if(file_data[:valid])
      # unless(file_data[:base_count]<=experiment.bioentry.biosequence.seq.length)
      #   self.warnings << ("Data out of bounds. #{file_data[:base_count]} datapoints found. #{experiment.bioentry.name} has #{experiment.bioentry.biosequence.seq.length}")
      # end
    else
      file_data[:errors].each do |e|
        self.warnings << (e)
      end
    end
  end
end