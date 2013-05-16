require 'stringio'
require 'base64'
require 'tempfile'

class Biosql::Biosequence < ActiveRecord::Base
  set_table_name "biosequence"
  set_primary_keys :bioentry_id, :version
  belongs_to :bioentry, :foreign_key => 'bioentry_id'
  
  def get_seq(start_pos, length)
    if self.class.connection.adapter_name.downcase =~/.*oracle.*/
      seq = ""
      max_chars = 4000
      # Select in batches of 4000
      (start_pos..(start_pos+length)).step(max_chars) do |pos|
        if(pos+max_chars>start_pos+length)
          char_num = (start_pos+length)-(pos)
        else
          char_num = max_chars
        end
        seq += self.class.connection.select_value("select dbms_lob.substr(seq,#{char_num},#{pos+1}) from biosequence where bioentry_id = #{bioentry_id} and version = #{version}")||''
      end
      return seq
    else
      # Check if seq is filled in or if we have removed it from the query using biosequence_without_seq association
      s = self.has_attribute?(:seq) ? self.seq : Biosql::Biosequence.find(self.id).seq
      return s[start_pos,length]
    end
  end
  
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

  def to_genbank(opts={})
    text = "ORIGIN\n"
    seq_pos = 1
    while(seq_pos < ([opts[:length],self.length].compact.min))
      line = get_seq(seq_pos,60)
      text+="#{seq_pos}".rjust(10)
      text+=" #{line.scan(/.{10}/).join(" ")}\n"
      seq_pos+=60
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
    Biosql::Feature::Cds.find_all_by_location(left,right,bioentry.id).each do |cds|
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
    if right > self.length; right=self.length;end
    o = offsets(left, right)
    cnt = 0
    trans_num = bioentry.taxon.genetic_code || 12
    my_array = []
    # 0, 1, 2  for first 3 frames
    # [id,x,w,sequence,frame#,offset]..]
    #adjust right to grab the overlap sequence
    r = (right-left)+3
    3.times do |x|
      my_array << [
        bioentry_id+left+cnt,
        (left.to_i+1), (right.to_i-left.to_i)+1,
        Bio::Sequence::NA.new(get_seq( (left+o[x]) , (r) )).translate(1,trans_num),
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
        Bio::Sequence::NA.new(get_seq( (left) , (r-o[x]) )).translate(4,trans_num),
        x+1,
        o[x]
      ]
      cnt +=1
    end
    return my_array
  end
  
  # writes GC data over the window size to the supplied IO.
  # Format is wig
  def write_gc_data(out_io,opts={})
    window = opts[:window]||50
    step = opts[:step]||20
    progress_bar = opts[:progress]||ProgressBar.new(self.length)
    total_written = 0
    write_wig_header(out_io,{:span => step})
    Bio::Sequence::NA.new(self.seq).window_search(window,step){ |x,y| out_io.write("#{y+1}\t#{x.gc_content.to_f}\n"); progress_bar.increment!(step); total_written+=step }
    progress_bar.increment!(self.length - total_written)
  end
  # writes a wig header to the supplied IO
  def write_wig_header(out_io,opts={})
    span = opts[:span]||20
    out_io.write("track type=wiggle_0 name=#{opts[:track_name]||'GC content'}\n") if opts[:track_line]==true
    out_io.write("variableStep chrom=#{bioentry_id} span=#{span}\n")
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
  
    case((length- right)%3)
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

