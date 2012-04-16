class FileManager
  require "open3"
  def self.save_file(file, directory="lib/data/")
    full_file = file.original_filename
    name = File.basename(full_file)
    f = name.split(".")
    path = File.join(directory, name)
    File.open(path, "w") { |f| f.write(file.read) }
    return name   
  end
  
  def self.wig_to_bigwig!(filein, fileout, chrom_file)
    if(File.exists?(fileout))
      File.delete(fileout)
    end
    wig_to_bigwig(filein, fileout, chrom_file)
  end
  
  def self.bigwig_info(path,options="")
    stdin, stdout, stderr = Open3.popen3("#{CMD_PATH}bigWigInfo '#{path}' #{options}")
    err = stderr.collect(&:to_s).join
    Rails.logger.info(err)
    puts err
    return stdout.collect.collect(&:to_s).join
  end
  
  def self.wig_to_bigwig(filein, fileout, chrom_file)
    fout = File.open("#{filein}.nohdr","w")
    fin = File.open(filein,"r")
    fin.each do |line|
      if(line.match(/\d+\s+\d*\.{0,1}\d*$/))
        fout.puts line
      end
    end
    stdin, stdout, stderr = Open3.popen3("#{CMD_PATH}wigToBigWig -clip '#{filein}.nohdr' '#{chrom_file}' '#{fileout}'")
    stderr.each do |e|
      puts e
    end
  end
  
  def self.bedgraph_to_bigwig(filein, fileout, chrom_file)
    stdin, stdout, stderr = Open3.popen3("#{CMD_PATH}bedGraphToBigWig '#{filein}' '#{chrom_file}' '#{fileout}'")
    stderr.each do |e|
      puts e
    end
  end
  
  def self.parse(file,hsh={})
    format = hsh[:format]
    data = {:valid => false, :errors => []}
    return data if file.nil?
    file.rewind
    case format.upcase
    when "MAQ_SNP"
      data[:valid]=true
    when "MAQ_INDEL"
      data[:valid]=true
    when "BIGWIG"
      stdin, stdout, stderr = Open3.popen3("#{CMD_PATH}validateFiles -type=bigWig '#{file.path}' -chromInfo=#{RAILS_ROOT}/lib/data/chrom.sizes")
      stderr.each do |e|
        data[:errors] << e.chomp.gsub(file.path," ") unless (e.chomp.blank? or e=~/Abort/)
      end
      data[:valid]=true if data[:errors].empty?
    when "WIG"
      data[:base_count]=0
      data[:blank_lines]=0
      #header def line
      definition = file.readline
      if(m=definition.match(/track\s(\w*type=(wiggle\w+).*)/) )
        data[:version] = m[2]
        definition.scan(/(\w+)=(".*?"|.*?)(\s|$)/).each do |match|
          data[match[0].to_sym]=match[1]
        end
        #wiggle declaration 
        declaration = file.readline
        if(m=declaration.match(/(variableStep|fixedStep)\schrom=(.+?)($|\sspan=(\d+))/))
          data[:format] = m[1]
          data[:chrom] = m[2]
          data[:span] = m[4] if m[4]
          #
          if (data[:format]=='fixedStep' && data[:step])
            step = data[:step]
          else
            step =1
          end
          # file.each do |line|
          #   data[:base_count]+=step
          #   if( (data[:format]=='variableStep' && line.match(/^(\d)+\s+(-{0,1}\d+|\d+.\d+)/)) || (data[:format]=='fixedStep' && line.match(/^(\d+)/)) )
          #     next
          #   elsif(line.chomp.empty?)
          #     data[:blank_lines]+=1
          #   else 
          #     data[:errors] << "Invalid Format:#{data[:base_count]+2} '#{line.to_s}'"
          #     return data
          #   end
          # end
          data[:valid]=true
        else
          data[:errors] << "Invalid Declaration: '#{declaration.to_s}'"
        end
      else
        data[:errors] << "Invalid Definition: '#{definition.to_s}'"
      end
    end
    return data
  end
     
end
