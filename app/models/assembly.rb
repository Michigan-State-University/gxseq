class Assembly < ActiveRecord::Base
  has_many :bioentries, :class_name => "Biosql::Bioentry", :order => "name asc", :dependent => :destroy
  has_many :experiments
  #TODO experiment STI - can this be dynamic?
  has_many :chip_chips, :order => "experiments.name asc"
  has_many :chip_seqs, :order => "experiments.name asc"
  has_many :synthetics, :order => "experiments.name asc"
  has_many :variants, :order => "experiments.name asc"
  has_many :rna_seqs, :order => "experiments.name asc"
  has_many :re_seqs, :order => "experiments.name asc"
  has_many :blast_runs, :dependent => :destroy
  has_many :blast_databases, :through => :blast_runs
  has_many :tracks
  has_many :models_tracks
  has_many :generic_feature_tracks
  has_many :concordance_sets
  has_one :six_frame_track
  # TODO: fix or remove protein sequence track
  #has_one :protein_sequence_track
  has_one :gc_file
  belongs_to :taxon, :class_name => "Biosql::Taxon"
  belongs_to :species, :class_name => "Biosql::Taxon", :foreign_key => :species_id
  belongs_to :group
  validates_presence_of :taxon
  validates_presence_of :version
  validates_uniqueness_of :version, :scope => :taxon_id
  
  # returns true if any bioentry -> seqfeature has feature_counts
  def has_expression?
    !bioentries.joins{seqfeatures.feature_counts}.except(:order).first.nil?
  end
  # returns name and version - use for display
  def name_with_version
    "#{name} ( #{version} )"
  end
  # returns scientific name of species
  def name
    taxon.name
  end
  # returns an array of all source terms used by features under this taxon
  def source_terms
    Biosql::Term.source_tags.where(:term_id => self.source_term_ids)
  end
  # returns the ids of all source_terms used by entries attached to this taxon
  def source_term_ids
    Biosql::Feature::Seqfeature.where(:bioentry_id => self.bioentry_ids).select('distinct source_term_id')
  end
  # returns the sum of bases for all bioentries
  def total_bases
    Biosql::Biosequence.where(:bioentry_id => self.bioentry_ids).sum(:length)
  end
  # Generates all denormalized data and indexes associations
  def sync
    puts "Generating GC data:"
    generate_gc_data
    puts "Creating Tracks"
    create_tracks
    puts "Creating Default Concordance"
    create_default_concordance
    puts "Reindexing Associations"
    reindex
  end
  # creates a default concordance set with accessions matching the database
  def create_default_concordance
    concordance_set = self.concordance_sets.find_or_create_by_name("Default")
    concordance_set.concordance_items.destroy_all
    progress_bar = ProgressBar.new(bioentries.count)
    bioentries.each do |entry|
      ConcordanceItem.fast_insert(:concordance_set_id => concordance_set.id, :bioentry_id => entry.bioentry_id,:reference_name => entry.accession)
      progress_bar.increment!
    end
  end
  # creates a big wig with the gc content data for all bioentries
  def generate_gc_data(opts={})
    destroy=opts[:destroy]||false
    window=opts[:window]||50
    progress_bar = ProgressBar.new(self.total_bases)
    begin
      if self.gc_file
        puts "\t\tFound existing for #{name_with_version}"
        if destroy == true
          puts "Destroy flag #{destroy} ... removing"
          self.gc_file.destroy
        else
          return
        end
      end
      puts "\t\tCreating new GC file for #{name_with_version}"
      # New ouput files for wig data
	    wig_file = File.open("tmp/assembly_#{self.id}_gc_data.txt", 'w')
	    chrom_file = File.open("tmp/assembly_#{self.id}_gc_chrom.txt","w")
	    # Have all the entries write gc data and chrom length
	    bioentries.includes(:biosequence).find_in_batches(:batch_size => 500) do |batch|
	      batch.each do |bioentry|
  	      # GC data in Wig format
  	      bioentry.biosequence.write_gc_data(wig_file,{:window => window, :progress => progress_bar})
  	      # Chrom name and length
  	      chrom_file.write("#{bioentry.bioentry_id}\t#{bioentry.biosequence.length}\n")
	      end
      end
      # flush write before conversion
      wig_file.flush
	    chrom_file.flush
	    # Attach new empty BigWig file
	    big_wig_file = File.open("tmp/assembly_#{self.id}_gc.bw","w+")
	    self.gc_file = GcFile.new(:data => big_wig_file)
	    self.save!
	    # Write out the BigWig data
	    FileManager.wig_to_bigwig(wig_file.path, self.gc_file.data.path, chrom_file.path)
	    # Close the files
	    wig_file.close
	    chrom_file.close
	    big_wig_file.close
    rescue 
      puts "Error creating GC_content file for taxon version(#{self.id})\n#{$!}\n\n#{$!.backtrace}"
    end
    # Cleanup the tmp files
    begin;FileUtils.rm("tmp/assembly_#{self.id}_gc_data.txt");rescue;puts $!;end
    begin;FileUtils.rm("tmp/assembly_#{self.id}_gc_chrom.txt");rescue;puts $!;end
    begin;FileUtils.rm("tmp/assembly_#{self.id}_gc.bw");rescue;puts $!;end
    puts
  end
  # initializes tracks creating any that do not exist. Returns an array of new tracks
  # TODO: Remove tracks completely. Just lookup the data during SV configuration
  def create_tracks
    result = []
    source_terms.each do |source_term|
      result << ModelsTrack.find_or_create_by_assembly_id_and_source_term_id(self.id,source_term.id)
      result << GenericFeatureTrack.find_or_create_by_assembly_id_and_source_term_id(self.id,source_term.id)
    end
    result << (six_frame_track || create_six_frame_track)
    #result << protein_sequence_track || create_protein_sequence_track
    return result
  end
  # Reindexes all associated data. Convienence method
  def reindex
    index_bioentries
    index_gene_models
    index_features
  end
  # indexes associated bioentries
  def index_bioentries
    bio_ids = bioentries.collect(&:id)
    Biosql::Bioentry.reindex_all_by_id(bio_ids)
  end
  # indexes associated genemodels
  def index_gene_models
    model_ids = GeneModel.where{bioentry_id.in my{bioentry_ids}}.select("id")
    GeneModel.reindex_all_by_id(model_ids)
  end
  # indexes seqfeatures for all bioentries
  # optionally accepts {:type => 'feature_type'} to scope indexing
  def index_features(opts={})
    terms = Biosql::Term.seqfeature_tags.select("term_id as type_term_id")
    terms = terms.where{name==my{opts[:type]}} if opts[:type]
    feature_ids = Biosql::Feature::Seqfeature.where{bioentry_id.in(my{self.bioentry_ids})}.where{type_term_id.in(terms)}.select("seqfeature_id").collect(&:id)
    Biosql::Feature::Seqfeature.reindex_all_by_id(feature_ids)
  end

  def bioentry_ids
    Biosql::Bioentry.select('bioentry_id').where{assembly_id == my{id}}
  end
  
  # TODO: Add method to quickly remove data and reindex. Current callbacks with destroy take far too long
  def remove_all_data
    # TODO: Remove the seqfeatures
    # remove the biosequence
    b_ids = bioentries.map(&:bioentry_id)
    b_ids.each_slice(999) do |batch|
      batch.each do |ids|
        Biosql::Biosequence.where{bioentry_id.in my{ids}}.delete_all
      end
    end
    # Remove the bioentries
  end
end