class Variant < Experiment
  has_many :variant_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  has_one :bcf, :foreign_key => "experiment_id"
  has_one :vcf, :foreign_key => "experiment_id"
  has_one :tabix_vcf, :foreign_key => "experiment_id"
  
  def asset_types
    {"vcf" => "Vcf", "tabix-vcf" => "TabixVcf", "bcf" => "Bcf"}
  end  
  
  def load_asset_data
    return false unless super
    begin
      if(vcf && !tabix_vcf)
        self.create_tabix_vcf(:data => vcf.create_tabix_vcf)
        tabix_vcf.load
      end
      # create the tracks again after we are done loading
      # the first attempt fails because we don't know what samples to use
      create_tracks
      return true
    rescue
      puts "Error loading Variant assets:\n#{$!}"
      return false
    end
  end
  # creates 1 track for each sample in the vcf and attaches them to the bioentry
  def create_tracks
    bioentries.each do |bioentry|
      self.samples.each do |samp|
        VariantTrack.find_or_create_by_bioentry_id_and_experiment_id_and_sample(bioentry.id,self.id,samp)
      end
    end
  end
  # returns the samples from tabix_vcf or bcf or an empty array
  def samples
    begin
      Array( (tabix_vcf || bcf).samples )
    rescue
      []
    end
  end
  # returns the data from tabix_vcf or bcf or an empty array
  # TODO: conver to summary_data for consistency and document asset methods
  def get_data(seq,start,stop,opts={})
  begin
    (tabix_vcf||bcf).get_data(seq,start,stop,opts)
  rescue 
    []
  end
  end
  
  def find_variants(seq,pos)
    begin
      get_data(seq,pos,pos,{:raw => true})
    rescue []
    end
  end
  
  # Method for searching other variants within a region for matching sequence
  # this method does NOT sanitize the positions or id
  def find_matches(start_pos, end_pos, bioentry_id, sample=nil)
    # an array to hold the results
    matching_variants = []
    # store this experiments converted sequence
    this_sequence = self.get_sequence(start_pos,end_pos,bioentry_id,sample)
    # grab all of the variant experiments
    BioentriesExperiment.includes(:experiment).where(:bioentry_id => bioentry_id).where(:experiment => {:type => 'Variant'}).map(&:experiment).each do |variant|
      next if variant == self #skip self
      # compute the variant sequence, compare to self and store if equal
      matching_variants << variant if  this_sequence == variant.get_sequence(start_pos,end_pos,bioentry_id,sample)
    end
    return matching_variants
  end
  
  # Method for returning altered base sequence using a window to apply sequence_variant diffs
  # This represents the strain/variant sequence in the given window
  # 
  def get_sequence(start,stop,bioentry_id,sample=nil,opts={})
    color_html = opts[:html]
    bioentry = Bioentry.find_by_bioentry_id(bioentry_id)
    return false unless bioentry
    #check boundaries
    start = 0 unless start >=0
    stop = bioentry.length unless stop <= bioentry.length
    #storing the deletion/insertion changes
    offset = 0
    #storing the possible alt alleles
    alleles = []
    #Get the sequence_variants within start and stop on given entry
    be = self.bioentries_experiments.find_by_bioentry_id(bioentry_id)
    usable_variants = self.get_data(be.sequence_name,start,stop,{:sample => sample,:only_variants => true}).reject{|a| a[:allele] != 1}.sort{|a,b|a[:pos]<=>b[:pos]}
    #Convert seq to array of indiv. bases
    seq_slice = bioentry.biosequence.seq[start-1,(stop-start)+1]
    if(seq_slice && seq_slice.length >=0)
      seq_a = seq_slice.split("")
      if(color_html)
        seq_a.collect!{|s|"<span style='background:whitesmoke;'>#{s}</span>"}
      end
    else
      return ""
    end
    #Apply the changes
    usable_variants.each_with_index do |v,idx|
      #setup alternate sequence
      # if(usable_variants[idx+1] && usable_variants[idx+1][:pos] == v[:pos])
      #   #next variant has same position (multiple alleles)
      #   alleles << v[:alt]
      #   next      
      # elsif(alleles.size > 0)
      #   #we have previous alleles indicating this is the last in the series
      #   alleles << v[:alt]
      #   #get the IUB Code for the ambiguous nucleotide
      #   alt = Variant::TO_IUB_CODE[alleles.sort]
      #   #clear out the alleles list
      #   alleles=[]        
      # else
        #just a standard variant
        alt = v[:alt]
      #end      
      alt_size = (v[:alt].nil? ? 0 : v[:alt].size)
      ref_size = (v[:ref].nil? ? 0 : v[:ref].size)
      #get the array index for this variant
      p = ((v[:pos])-start)+offset
      #convert ref seq to alt seq
      if(color_html)
        if alt_size < ref_size
          # deletion
          a = (alt||'').split("").collect{|s|"<span title='Deletion&nbsp;-&nbsp;Ref:&nbsp;#{v[:ref]}&nbsp;Alt:&nbsp;#{v[:alt]}'style='background:salmon;'>#{s}</span>"}
        elsif alt_size > ref_size
          # insertion
          a = (alt||'').split("").collect{|s|"<span title='Insertion&nbsp;-&nbsp;Ref:&nbsp;#{v[:ref]}&nbsp;Alt:&nbsp;#{v[:alt]}'style='background:lightgreen;'>#{s}</span>"}
        elsif alt_size == ref_size
          # snp
          a = (alt||'').split("").collect{|s|"<span title='Snp&nbsp;-&nbsp;Ref:&nbsp;#{v[:ref]}&nbsp;Alt:&nbsp;#{v[:alt]}'style='background:lightblue;'>#{s}</span>"}
        end
        seq_a[p,v[:ref].size]=a
      else
        seq_a[p,v[:ref].size]=(alt.nil? ? [] : alt.split(""))
      end
      #update the offset
      offset +=(alt_size - ref_size)
    end
    #convert the array back to a string
    return seq_a.join("")
  end
  
  #For conversion from SNP using IUB codes
  TO_IUB_CODE =	{
    ['A'] => 'A',
    ['C'] => 'C',
    ['T'] => 'T',
    ['G'] => 'G',
    ['A','C'] => 'M', 
    ['G','T'] => 'K',
    ['C','T'] => 'Y', 
    ['A','G'] => 'R', 
    ['A','T'] => 'W', 
    ['G','C']   => 'S',
    ['A','G','T'] => 'D',
    ['C','G','T'] => 'B',
    ['A','C','T'] => 'H',
    ['A','C','G'] => 'V',
    ['A','C','G','T'] => 'N'
  }
  
  IUB_CODE = {
    'A' => ['A'],
    'C' => ['C'],
    'T' => ['T'],
    'G' => ['G'],
    'M' => ['A','C'], 
    'K' => ['G','T'], 
    'Y' => ['C','T'], 
    'R' => ['A','G'], 
    'W' => ['A','T'], 
    'S' => ['G','C'],   
    'D' => ['A','G','T'], 
    'B' => ['C','G','T'],
    'H' => ['A','C','T'],
    'V' => ['A','C','G'],
    'N' => ['A','C','G','T'] 
  }
    

end