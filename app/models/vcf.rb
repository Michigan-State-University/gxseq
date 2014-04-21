# == Schema Information
#
# Table name: assets
#
#  created_at        :datetime
#  data_content_type :string(255)
#  data_file_name    :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#  sample_id     :integer
#  id                :integer          not null, primary key
#  state             :string(255)      default("pending")
#  type              :string(255)
#  updated_at        :datetime
#

class Vcf < Asset
  def unload
    remove_temp_files
  end
  
  def create_bcf
    File.open(Bio::DB::SAM::Bcf.vcf_to_bcf(data_path),"r")
  end
  
  def create_tabix_vcf
    Bio::Tabix::TFile.compress(data_path,data_path+".bgzf")
    File.open(data_path+".bgzf","r")
  end
  
  def remove_temp_files
    d = Dir.new(File.dirname(data_path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.filename) && f.match(/\.bcf$|\.bgzf$/) )
    end
  end
end
