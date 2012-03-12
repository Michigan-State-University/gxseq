class Vcf < Asset
  def create_bcf
    File.open(Bio::DB::SAM::Bcf.vcf_to_bcf(data.path),"r")
  end
  
  def remove_temp_files
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.full_filename) && f.match(/\.bcf$/) )
    end
  end
end