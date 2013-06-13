require 'open3'
STDOUT.sync = true
# usage fix_clc_coord s1.bam gene_loc.txt /path/to/samtools reference.fa s1.out
file = File.open(ARGV[1])
samtools_path = ARGV[2]
ref_fa = ARGV[3]
indexed_fa = ARGV[3]+'.fai'
temp_file = File.open(ARGV[4]+'.tmp',"w")
hsh = {}
# HSH data file should be Gene,start,stop,Chr,Strand
file.each do |line|
  data = line.chomp.split(",")
  hsh[data[0]]=data
end

# Bam view opens bad bam and passes to ruby
bam_view_in, bam_view_out, bam_view_err = Open3.popen3("#{samtools_path} view #{ARGV[0]}")

puts "Processing bam"
count = 0
while bam_line = bam_view_out.gets
  count+=1
  printf "--#{count}\r" if count%10000==0
  sam_data = bam_line.split("\t")
  id=sam_data[2]
  puts id unless hsh[id]
  strand=hsh[id][4].to_i
  # Set Reference name to chromosome instead of Gene
  sam_data[2]=hsh[id][3]
  if(strand==1)
    # Add Gene start to position (-1 for switch from 1-based to 0 based)
    sam_data[3]=(sam_data[3].to_i+hsh[id][1].to_i-1)
  else
   # Reverese strand genes need to reverse complement everything
   # Subtract position and seq length from gene end_pos
   sam_data[3]=(hsh[id][2].to_i-((sam_data[3].to_i+sam_data[9].length)-2))
   # reverse complement the seq
   sam_data[9].reverse!
   sam_data[9].tr!('atcgATCG','tagcTAGC')
  end
  # Write to the sam input where it is waiting for standard in
  temp_file.puts sam_data.join("\t")
end
while bam_err = bam_view_err.gets
  puts bam_err
end
temp_file.close

# This should probably be a forked process waiting for output from above but this was quicker to setup
# Sam view converts new sam back to bam using indexed fa and passes to calmd
# calmd checks all the mismatches, sets the md line and sends the bam to sort for final output
`#{samtools_path} view -uSt #{indexed_fa} #{ARGV[4]+'.tmp'} | #{samtools_path} calmd -u - #{ref_fa} | #{samtools_path} sort -m 1000000000 - #{ARGV[4]}`

puts "Done"
