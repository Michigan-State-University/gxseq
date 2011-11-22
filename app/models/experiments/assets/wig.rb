class Wig < Asset
  def check_data_format
    #only validate once
    self.validated = true
    file_data = FileManager.parse(self.data.queued_for_write[:original], {:format => self.class.name})
    unless(file_data[:valid])
      file_data[:errors].each do |e|
        self.warnings << (e)
      end
    end
  end
end