class FileManager
  require "open3"
  
  def self.wig_to_bigwig!(filein, fileout, chrom_file)
    if(File.exists?(fileout))
      File.delete(fileout)
    end
    wig_to_bigwig(filein, fileout, chrom_file)
  end
  
  def self.wig_to_bigwig(filein, fileout, chrom_file)
    fout = File.open("#{filein}.nohdr","w")
    fin = File.open(filein,"r")
    fin.each do |line|
      if(line.match(/^\d+\s+\d*\.{0,1}\d*$/) || line.match(/(variableStep|fixedStep)\schrom=(.+?)($|\sspan=(\d+))/))
        fout.puts line
      end
    end
    fout.flush
    Bio::Ucsc::Util.wig_to_big_wig("#{filein}.nohdr",chrom_file,fileout).close
    fout.close
    fin.close
  end
  
  def self.bedgraph_to_bigwig(filein, fileout, chrom_file)
    Bio::Ucsc::Util.bed_graph_to_big_wig(filein,chrom_file,fileout)
  end
     
end
