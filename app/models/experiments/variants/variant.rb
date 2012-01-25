class Variant < Experiment
  has_many :variant_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  has_many :sequence_variants, :foreign_key => "experiment_id", :dependent => :delete_all
  has_many :snps, :foreign_key => "experiment_id"
  has_many :indels, :foreign_key => "experiment_id"
  has_many :deletions, :foreign_key => "experiment_id"
  has_many :insertions, :foreign_key => "experiment_id"
  
  def asset_types
    {"MAQ snp" => "MaqSnp", "MAQ indel" => "MaqIndel"}
  end  
  
  def max_pos
    SequenceVariant.find(:first, :order => "pos desc").pos
  end
  
  def variant_counts(num,bioentry_id)
    return [] unless num.is_a?(Integer) and num > 0
    return [] unless bioentry = Bioentry.find(bioentry_id)
    piece = (bioentry.length/num).floor
    SequenceVariant.find_by_sql("SELECT (FLOOR(pos/#{piece})*#{piece})/#{bioentry.length} as percent, FLOOR(pos/#{piece})*#{piece} as pos, COUNT(*) as count FROM sequence_variants where bioentry_id = #{bioentry.id} AND experiment_id = #{self.id} GROUP BY FLOOR(pos/#{piece})*#{piece}")
  end
  
  def remove_asset_data
    puts "Removing all Asset Data - #{Time.now}"
    SequenceVariant.paper_trail_off
    SequenceVariant.delete_all(["experiment_id = ?",self.id])
    SequenceVariant.paper_trail_on
  end
  
  def create_tracks
    bioentries.each do |bioentry|
      VariantTrack.find_or_create_by_bioentry_id_and_experiment_id(bioentry.id,self.id)
    end
  end
  
  # Method for searching other variants within a region for matching sequence
  # this method does NOT sanitize the positions or id
  def find_matches(start_pos, end_pos, bioentry_id)
    # an array to hold the results
    matching_variants = []
    # store this experiments converted sequence
    this_sequence = self.get_sequence(start_pos,end_pos,bioentry_id)
    # grab all of the variant experiments
    BioentriesExperiment.find_all_by_bioentry_id(bioentry_id).map(&:experiment).each do |variant|
      next if variant == self #skip self
      # compute the variant sequence, compare to self and store if equal
      matching_variants << variant if  this_sequence == variant.get_sequence(start_pos,end_pos,bioentry_id)
    end
    return matching_variants
  end
  
  # Method for returning altered base sequence using a window to apply sequence_variant diffs
  # This represents the strain/variant sequence in the given window
  def get_sequence(start,stop,bioentry_id)
    bioentry = Bioentry.find(:first, :conditions => ["#{Bioentry.table_name}.#{Bioentry.primary_key}=?",bioentry_id])
    return false unless bioentry
    #check boundaries
    start = 0 unless start >=0
    stop = bioentry.length unless stop <= bioentry.length
    #storing the deletion/insertion changes
    offset = 0
    #storing the possible alt alleles
    alleles = []
    #Get the sequence_variants within start and stop on given entry
    usable_variants = sequence_variants.find(:all,:conditions => ["pos between ? AND ? AND bioentry_id = ?",start,stop,bioentry_id], :order => "pos")
    #Convert seq to array of indiv. bases
    seq_slice = bioentry.biosequence.seq[start-1,(stop-start)+1]
    if(seq_slice && seq_slice.length >=0)
      seq_a = seq_slice.split("")
    else
      return ""
    end
    #Apply the changes
    usable_variants.each_with_index do |v,idx|
      #setup alternate sequence
      if(usable_variants[idx+1] && usable_variants[idx+1].pos == v.pos)
        #next variant has same position (multiple alleles)
        alleles << v.alt
        next      
      elsif(alleles.size > 0)
        #we have previous alleles indicating this is the last in the series
        alleles << v.alt
        #get the IUB Code for the ambiguous nucleotide
        alt = SequenceVariant::TO_IUB_CODE[alleles.sort]
        #clear out the alleles list
        alleles=[]        
      else
        #just a standard variant
        alt = v.alt
      end      
      alt_size = (v.alt.nil? ? 0 : v.alt.size)
      ref_size = (v.ref.nil? ? 0 : v.ref.size)
      #get the array index for this variant
      p = ((v.pos)-start)+offset
      #convert ref seq to alt seq
      seq_a[p,v.ref.size]=(alt.nil? ? [] : alt.split(""))
      #update the offset
      offset +=(alt_size - ref_size)
    end
    #convert the array back to a string
    return seq_a.join("")
  end
  
end