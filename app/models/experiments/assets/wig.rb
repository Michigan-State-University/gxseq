class Wig < Asset
  # convert wig to big_wig and save as a new asset
  def create_big_wig(chrom_file_path)
    begin
      FileManager.wig_to_bigwig(self.data.path, temp_big_wig_path, chrom_file_path)
      File.open(temp_big_wig_path,'r')
    rescue
      logger.error("#{Time.now} \n #{$!}")
      puts "Error: could not convert wig to BigWig #{Time.now}"
    end
  end
  # removes any generated data and updates state
  def unload
    remove_temp_files
    update_attribute(:state, "pending")
  end
  
  def remove_temp_files
    d = Dir.new(File.dirname(data.path))
    d.each do |f|
      File.delete(d.path+"/"+f) if( f.match(self.filename) && f.match(/\.bw_tmp$|\.chrom\.sizes$/) )
    end
  end
  
  def temp_big_wig_path
    self.data.path+"\.bw_tmp"
  end
  
end