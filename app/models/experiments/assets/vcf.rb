class Vcf < Asset
  def unload
    remove_temp_files
  end
  
  def create_bcf
    File.open(Biosql::DB::SAM::Bcf.vcf_to_bcf(data.path),"r")
  end
  
  def create_tabix_vcf
    Biosql::Tabix::TFile.compress(data.path,data.path+".bgzf")
    File.open(data.path+".bgzf","r")
  end
  
  def remove_temp_files
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.filename) && f.match(/\.bcf$|\.bgzf$/) )
    end
  end
end