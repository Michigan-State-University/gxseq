# == Schema Information
#
# Table name: assemblies
#
#  created_at :datetime
#  group_id   :integer
#  id         :integer          not null, primary key
#  species_id :integer
#  taxon_id   :integer
#  type       :string(255)
#  updated_at :datetime
#  version    :string(255)
#

class Assembly < ActiveRecord::Base
  has_many :bioentries, :class_name => "Biosql::Bioentry", :order => "name asc", :dependent => :destroy
  has_many :samples, :order => "samples.type asc, samples.name asc"
  #NOTE sample STI - can this be dynamic?
  has_many :chip_chips, :order => "samples.name asc"
  has_many :chip_seqs, :order => "samples.name asc"
  has_many :combos, :order => "samples.name asc"
  has_many :variants, :order => "samples.name asc"
  has_many :rna_seqs, :order => "samples.name asc"
  has_many :re_seqs, :order => "samples.name asc"
  has_many :blast_runs, :dependent => :destroy
  has_many :blast_databases, :through => :blast_runs
  has_many :tracks
  has_many :models_tracks
  has_many :generic_feature_tracks
  has_many :concordance_sets
  has_one :six_frame_track
  has_one :gc_file
  belongs_to :taxon, :class_name => "Biosql::Taxon"
  belongs_to :species, :class_name => "Biosql::Taxon", :foreign_key => :species_id
  belongs_to :group
  validates_presence_of :taxon
  validates_presence_of :version
  validates_uniqueness_of :version, :scope => :taxon_id
  accepts_nested_attributes_for :samples
  validates_associated :samples
  
  acts_as_api
  
  api_accessible :listing do |t|
    t.add :id
    t.add :type
    t.add :species_id
    t.add 'species.scientific_name.name', :as => :species
    t.add :taxon_id
    t.add 'taxon.scientific_name.name', :as => :taxon
    t.add :version
  end
  
  # Defined in subclasses
  def default_tracks
  end
  # returns uniq list of terms for traits associated with samples
  def trait_types
    samples.map(&:trait_types).flatten.compact.uniq
  end
  # returns true if any bioentry -> seqfeature has feature_counts
  def has_expression?
    !bioentries.joins{seqfeatures.feature_counts}.except(:order).first.nil?
  end
  # returns name and version - use for display
  def name_with_version
    "#{name} ( #{version} )"
  end
  # returns scientific name of taxon or strain
  def name
    taxon.name
  end
  # returns the scientific name of the species
  def species_name
    species.name
  end
  # returns an array of all source terms used by features under this taxon
  def source_terms
    Biosql::Term.source_tags.where(:term_id => self.source_term_ids)
  end
  # returns the ids of all source_terms used by entries attached to this taxon
  def source_term_ids
    Biosql::Feature::Seqfeature.where(:bioentry_id => self.bioentry_ids).select('distinct source_term_id')
  end
  # returns all gene models
  def gene_models
    GeneModel.where{bioentry_id.in my{self.bioentries}}
  end
  # returns all gene features
  def gene_features
    Biosql::Feature::Gene.where{bioentry_id.in my{self.bioentries}}
  end
  # returns all cds features
  def cds_features
    Biosql::Feature::Cds.where{bioentry_id.in my{self.bioentries}}
  end
  # returns all mrna features
  def mrna_features
    Biosql::Feature::Mrna.where{bioentry_id.in my{self.bioentries}}
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
      wig_file = Tempfile.new("assembly_#{self.id}_gc_data.txt")
      chrom_file = Tempfile.new("assembly_#{self.id}_gc_chrom.txt")
      big_wig_file = Tempfile.new("assembly_#{self.id}_gc.bw")
      begin
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
        self.gc_file = GcFile.new(:data => big_wig_file)
        self.save!
        # Write out the BigWig data
        FileManager.wig_to_bigwig(wig_file.path, self.gc_file.data_path, chrom_file.path)
      # Close the files
      ensure
        wig_file.close
        wig_file.unlink
        chrom_file.close
        chrom_file.unlink
        big_wig_file.close
        big_wig_file.unlink
      end
    rescue 
      puts "Error creating GC_content file for taxon version(#{self.id})\n#{$!}\n\n#{$!.backtrace}"
    end
    puts
  end
  # initializes tracks creating any that do not exist. Returns an array of new tracks
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
  
  # loops over features and calls block
  def iterate_features(opts={})
    # Setup the search
    search = feature_search(opts)
    current_page = 1
    total_pages = search.hits.total_pages
    bar = ProgressBar.new(search.total)
    if(search.total > 0)
      puts "Found #{search.total} features..."
    else
      if opts[:type]
        puts "0 #{opts[:type]} features found"
        search = Biosql::Feature::Seqfeature.search do
          with :assembly_id, self.id
          facet :display_name
        end
        if search.total > 0
          puts "Try one of these:\n"
          search.facet(:display_name).rows.each do |row|
            puts "\t#{row.value} : #{row.count}"
          end
          return false
        else
          puts "0 alternates found"
        end
      else
        puts "0 features found"
      end
    end
    # initial output
    yield search
    bar.increment!(search.hits.length)
    # Start main loop - Work in batches to avoid large memory use
    while(current_page < total_pages)
      current_page+=1
      yield feature_search(opts.merge(:page => current_page))
      bar.increment!(search.hits.length)
    end
  end
  
  # returns a search object matching with results from the supplied options
  def feature_search(opts={})
    per_page = opts[:per_page]||500
    page = opts[:page]||1
    
    Biosql::Feature::Seqfeature.search do
      if(opts[:type])
        with :display_name, opts[:type]
      end
      if(opts[:locus_list])
        with :locus_tag, opts[:locus_list]
      end
      with :assembly_id, self.id
      order_by :locus_tag
      paginate(:page => page, :per_page => per_page)
    end
  end
  
  # removes all data skipping destroy callbacks for speed
  # TODO: Need method to sync index with removed assembly?
  def delete_all_data
    PaperTrail.enabled = false
    begin
      # all or nothing
      Assembly.transaction do
        
        b_ids = bioentries.select("bioentry_id").except(:order)
        # seqfeature assoc
        features = Biosql::Feature::Seqfeature.where{bioentry_id.in my{b_ids}}
        fea_ids = features.select("seqfeature_id").except(:order)
        Biosql::SeqfeatureQualifierValue.where{seqfeature_id.in my{fea_ids}}.delete_all
        Biosql::Location.where{seqfeature_id.in my{fea_ids}}.delete_all
        features.delete_all
        # bioentry assoc
        Biosql::Biosequence.where{bioentry_id.in my{b_ids}}.delete_all
        Biosql::BioentryDbxref.where{bioentry_id.in my{b_ids}}.delete_all
        Biosql::BioentryQualifierValue.where{bioentry_id.in my{b_ids}}.delete_all
        Biosql::BioentryReference.where{bioentry_id.in my{b_ids}}.delete_all
        Biosql::Comment.where{bioentry_id.in my{b_ids}}.delete_all
        GeneModel.where{bioentry_id.in my{b_ids}}.delete_all
        ConcordanceItem.where{bioentry_id.in my{b_ids}}.delete_all
        Peak.where{bioentry_id.in my{b_ids}}.delete_all
        # TODO: test this delte on >1000 ids
        Biosql::Bioentry.where{bioentry_id.in my{b_ids.map(&:bioentry_id)}}.delete_all
        # assembly assoc
        BlastRun.where{assembly_id == my{id}}.delete_all
        Track.where{assembly_id == my{id}}.delete_all
        ConcordanceSet.where{assembly_id == my{id}}.delete_all
        # Use destroy on paperclip attachments
        samples.destroy_all
        gc_file.destroy
      end
    rescue => e
      puts "Error: #{e}"
    end
    PaperTrail.enabled = true
  end
end
