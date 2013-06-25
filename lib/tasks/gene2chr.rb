require 'open3'
require 'strscan'
STDOUT.sync = true
if ARGV.length != 5
  puts "\t--usage: gene2chr gene.in.bam gene_loc.txt /path/to/samtools reference.fa chr.out.bam"
  puts "\t--- gene.in.bam => locus aligned bam"
  puts "\t--- gene_loc.txt => csv with: LocusID,Start,Stop,ChrID,Strand(1,-1)"
  puts "\t--- /path/to/samtools => samtools binary"
  puts "\t--- reference.fa => chromosome fasta file and *.fai - see samtools faidx"
  puts "\t--- chr.out.bam => new chr aligned bam"
  exit
end
bam_infile = ARGV[0]
gene_loc_file = File.open(ARGV[1])
samtools_path = ARGV[2]
ref_fa = ARGV[3]
indexed_fa = ARGV[3]+'.fai'
bam_out = ARGV[4]
hsh = {}
# HSH data file should be Gene,start,stop,Chr,Strand
gene_loc_file.each do |line|
  data = line.chomp.split(",")
  hsh[data[0]]=data
end
# parse cigar, count ops that add to length returning total and reversed cigar.
@cnt_reg = /\d+/
@op_reg = /\D/
def count_and_reverse_cigar(cigar_string)
  length = 0
  cigar = []
  scanner = StringScanner.new(cigar_string)
  while( cnt = scanner.scan(@cnt_reg))
    cnt = cnt.to_i
    op = scanner.scan(@op_reg)
    if(op == 'M' || op == 'D' || op == 'N' || op == '=' || op == 'X')
      length += cnt
    end
    cigar << "#{cnt}#{op}"
  end
  return length,cigar.reverse.join('')
end
# Bam view opens bad bam and passes to ruby
bam_view_in, bam_view_out, bam_view_err = Open3.popen3("#{samtools_path} view #{bam_infile}")
# Sam view converts new sam back to bam using indexed fa and passes to calmd
# calmd checks all the mismatches, sets the md line and sends the bam to sort for final output
bam_write_in, bam_write_out, bam_write_err = Open3.popen3("#{samtools_path} view -uSt #{indexed_fa} -o - - | #{samtools_path} calmd -u - #{ref_fa} | #{samtools_path} sort - #{bam_out}")
puts "Processing bam"
count = 0
while bam_line = bam_view_out.gets
  # Count and Log
  count+=1
  printf "--#{count}\r" if count%10000==0
  # Parse the line
  sam_data = bam_line.split("\t")
  # id
  id=sam_data[2]
  puts id unless hsh[id]
  # START CHANGES
  strand=hsh[id][4].to_i
  # Set Reference name to chromosome instead of Gene
  sam_data[2]=hsh[id][3]
  if(strand==1)
    # Add Gene start to position (-1 for switch from 1-based to 0 based)
    sam_data[3]=(sam_data[3].to_i+hsh[id][1].to_i-1)
  else
   # Reverese strand genes need to reverse complement everything
   ##
   end_pos=hsh[id][2].to_i+1
   pos=sam_data[3].to_i-1
   # get mapped length and reversed cigar
   map_length, sam_data[5] = count_and_reverse_cigar(sam_data[5])
   # Subtract mapping pos and seq length from gene end_pos
   sam_data[3]=end_pos-(map_length+pos)
   # reverse complement the seq
   sam_data[9].reverse!
   sam_data[9].tr!('atcgATCG','tagcTAGC')
  end
  # Write to the temp file
  #temp_file.puts sam_data.join("\t")
  bam_write_in.puts sam_data.join("\t")
end
while bam_err = bam_view_err.gets
  puts bam_err
end
bam_write_in.close
while bam_out=bam_write_out.gets
  puts bam_out
end
while bam_err = bam_write_err.gets
  puts bam_write_err
end
puts "Done"