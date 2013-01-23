require 'stringio'
require 'base64'
require 'tempfile'
require 'fileutils'

class Biosequence < ActiveRecord::Base
  set_table_name "biosequence"
  set_primary_keys :bioentry_id, :version
  belongs_to :bioentry, :foreign_key => 'bioentry_id'
  has_many :sequence_files, :foreign_key => [:bioentry_id, :version], :dependent => :destroy
  has_one :gc_file, :class_name  => "GcFile", :foreign_key => [:bioentry_id, :version]
  
  
  def self.to_protein(sequence,frame=1,genetic_code=1)
    frame = frame.to_i
    genetic_code = genetic_code.to_i
    [1,2,3].include?(frame)||frame=1
    genetic_code>0||genetic_code=1
    return Bio::Sequence::NA.new(sequence).translate(frame,genetic_code)
  end

  def to_fasta
    s = ""
    s+=">#{bioentry.accession} #{bioentry.description}\n"
    s+="#{self.seq.to_formatted}"
  end
  
  def yield_fasta
    seq.scan(/.{100}/).each do |line|
      yield "#{line}\n"
    end
  end

  def to_genbank
    text = "ORIGIN\n"
    seq_count = 1
    seq.scan(/.{60}/).each do |line|
      text+="#{seq_count}".rjust(10)
      text+=" #{line.scan(/.{10}/).join(" ")}\n"
      seq_count+=60
    end
    return text
  end
  
  def yield_genbank
    yield "ORIGIN\n"
    seq_count = 1
    seq.scan(/.{60}/).each do |line|
      yield "#{seq_count}".rjust(10)+" #{line.scan(/.{10}/).join(" ")}\n"
      seq_count+=60
    end
  end
  
  # TODO: refactor, this method is too tightly coupled
  def get_protein_sequence(id,left,right)
    # [bioseq.ent_oid+left, left, length, data]
    return [] if left > length
    if right > seq.length; right=seq.length;end
    trans_num = bioentry.taxon.genetic_code || 12
    my_array = []
    Cds.find_all_by_location(left,right,bioentry.id).each do |cds|
      gm = GeneModel.find(:all, :conditions => "bioentry_id = '#{bioentry.id}' AND start_pos < '#{right}' AND end_pos > '#{left}'AND cds_id = '#{cds.id}'")
      start_codon = 1
      cds.locations.each do |loc|
        sequence = ''
        start_codon = (loc.strand ? start_codon : start_codon += 3)
        orig_sequence = Bio::Sequence::NA.new(seq[(loc.start_pos - 1), ((loc.end_pos - loc.start_pos)+ 1)]).translate(start_codon,trans_num)
        orig_sequence.each_byte do |ws|
          sequence += ws.chr+"  ";
        end
      # my_array << [id, loc.start_pos, sequence.size, sequence, locus_tag]
      my_array << [id+loc.start_pos, loc.start_pos, (loc.end_pos - loc.start_pos), sequence, gm.first.locus_tag]
      end
    end
    my_array.sort
  end

  def get_six_frames(left, right)
    return [] if left > length
    if right > seq.length; right=seq.length;end
    o = offsets(left, right)
    cnt = 0
    trans_num = bioentry.taxon.genetic_code || 12
    full_seq = seq
    my_array = []
    # 0, 1, 2  for first 3 frames
    # [id,x,w,sequence,frame#,offset]..]
    #adjust right to grab the overlap sequence
    r = (right-left)+3
    3.times do |x|
      my_array << [
        bioentry_id+left+cnt,
        (left.to_i+1), (right.to_i-left.to_i)+1,
        Bio::Sequence::NA.new(full_seq[ (left+o[x]) , (r) ]).translate(1,trans_num),
        x+1,
        o[x]
      ]
      cnt +=1
    end
    # 3, 4, 5 for second 3 frames
    # adjust left to grab any overlap sequence
    left = left-3
    if left < 0; left = 0;end
    r = (right-left)
    (3..5).each do |x|
      my_array << [
        bioentry_id+left+cnt,
        (left.to_i+1), (right.to_i-left.to_i),
        Bio::Sequence::NA.new(full_seq[ (left) , (r-o[x]) ]).translate(4,trans_num),
        x+1,
        o[x]
      ]
      cnt +=1
    end
    return my_array
  end
  
  def get_gc_content(left=0,length=0,bases=2)
    left = [left,self.length-1].min
    right = [(left + length),self.length].min
    points =((right-left)/(20*bases)).ceil
    points = 1 if points <= 0 
    step = ((right-left)/points).ceil
    self.gc_file.summary_data(left,right+step,points+1).map{|d| [d,step]}
  end
  
  # create a big wig with the gc content data for this biosequence
  def generate_gc_data(precision=50, destroy=false)  
    desc = bioentry.description
    begin
      if self.gc_file
        return unless destroy
        puts "\t\tFound existing for #{desc} so removing"
        self.gc_file.destroy
      end
      puts "\t\tCreating new GC file for #{desc}"
      # Write out GC data in Wig format
	    wig_file = File.open("tmp/#{self.bioentry_id}_gc_data.txt", 'w')
	    wig_file.write("track type=wiggle_0 name=GC content\nvariableStep chrom=#{bioentry_id} span=1\n")
	    Bio::Sequence::NA.new(self.seq).window_search(precision,precision){ |x,y| wig_file.write("#{y+1}\t#{x.gc_content.to_f}\n") }
	    wig_file.flush	    
	    # write the chrom size file
	    chrom_file = File.open("tmp/#{self.bioentry_id}_gc_chrom.txt","w")
	    chrom_file.write("#{bioentry_id}\t#{seq.length}")
	    chrom_file.flush	    
	    # Attach new empty BigWig file
	    big_wig_file = File.open("tmp/#{self.bioentry_id}_gc.bw","w+")
	    self.gc_file = GcFile.new(:data => big_wig_file)
	    self.save!	    
	    # Write out the BigWig data
	    FileManager.wig_to_bigwig(wig_file.path, self.gc_file.data.path, chrom_file.path)
	    # Close the files
	    wig_file.close
	    chrom_file.close
	    big_wig_file.close
    rescue 
      puts "Error creating GC_content file for biosequence(#{self.id})\n#{$!}\n\n#{$!.backtrace}"
    end
    # Cleanup the tmp files
    begin;FileUtils.rm("tmp/#{self.bioentry_id}_gc_chrom.txt");rescue;puts $!;end
    begin;FileUtils.rm("tmp/#{self.bioentry_id}_gc_data.txt");rescue;puts $!;end
    begin;FileUtils.rm("tmp/#{self.bioentry_id}_gc.bw");rescue;puts $!;end    
  end

  def offsets(left, right)
    case (left%3)
    when 0
      o = [0,1,2]
    when 1
      o = [2,0,1]
    when 2
      o = [1,2,0]        
    end
  
    case((seq.length- right)%3)
    when 0
      o << [0,1,2]
    when 1
      o << [2,0,1]
    when 2
      o << [1,2,0]        
    end
    return o.flatten
  end
  
end


# == Schema Information
#
# Table name: sg_biosequence
#
#  ent_oid    :integer(38)     not null, primary key
#  version    :decimal(3, 1)
#  length     :integer(38)
#  alphabet   :string(12)
#  seq        :text
#  crc        :string(32)
#  deleted_at :datetime
#  updated_at :datetime
#

