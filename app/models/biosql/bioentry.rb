class Bioentry < ActiveRecord::Base
  set_table_name "bioentry"
  set_primary_key :bioentry_id
  belongs_to :biodatabase, :class_name => "Biodatabase"
  belongs_to :taxon_version

  has_one :biosequence, :dependent  => :destroy
  has_one :biosequence_without_seq, :class_name => "Biosequence", :select => [:alphabet,:length,:version,:created_at,:updated_at]
  
  has_many :bioentry_dbxrefs, :class_name => "BioentryDbxref", :dependent  => :destroy
  has_many :bioentry_qualifier_values, :order=>"bioentry_id,term_id,rank", :class_name => "BioentryQualifierValue", :dependent  => :destroy
  has_many :bioentry_references, :class_name=>"BioentryReference", :dependent  => :destroy
  has_many :comments, :class_name =>"Comment", :order =>'rank', :dependent  => :destroy
  has_many :object_bioentry_relationships, :class_name=>"BioentryRelationship", :foreign_key=>"object_bioentry_id", :dependent  => :destroy  
  has_many :object_bioentry_paths, :class_name=>"BioentryPath", :foreign_key=>"object_bioentry_id", :dependent  => :destroy 
  has_many :references, :through=>:bioentry_references, :class_name => "Reference"
  has_many :seqfeatures, :order => "rank", :dependent  => :destroy
  has_many :subject_bioentry_relationships, :class_name=>"BioentryRelationship", :foreign_key=>"subject_bioentry_id", :dependent  => :destroy
  has_many :subject_bioentry_paths, :class_name=>"BioentryPath", :foreign_key=>"subject_bioentry_id", :dependent  => :destroy
  has_many :terms, :through=>:bioentry_qualifier_values, :class_name => "Term"
    
  #seqfeature types
  has_many :source_features, :class_name => "Source"
  has_many :gene_features, :class_name => "Gene"
  has_many :cds_features, :class_name => "Cds"
  has_many :mrna_features, :class_name => "Mrna"
  
  ##Extensions
  has_many :gene_models, :dependent  => :destroy
  has_many :bioentries_experiments
  has_many :experiments, :through => :bioentries_experiments
  has_many :chip_seqs, :through => :bioentries_experiments
  has_many :chip_chips, :through => :bioentries_experiments
  has_many :synthetics, :through => :bioentries_experiments
  has_many :variants, :through => :bioentries_experiments
  has_many :tracks, :dependent => :destroy
  has_many :peaks
  has_one :gc_file
  
  #has_many :models_tracks # TODO: allow multiple sources
  #has_many :generic_feature_tracks# TODO: allow multiple sources
  has_one :models_track
  has_one :six_frame_track
  has_one :protein_sequence_track
  has_one :generic_feature_track
  
  
  scope :with_version, lambda { |v| where("version = ?",v) }
  has_paper_trail :version => 'paper_trail_version', :versions => 'paper_trail_versions'
  acts_as_api
  
  # Sunspot search definition
  searchable(:include => [[:bioentry_qualifier_values, :taxon_version => [:species => :scientific_name]], [:source_features => [:qualifiers => :term]]]) do
    text :qualifiers, :stored => true do
      qualifiers.map{|q|"#{q.name}: #{q.value}"}
    end
    text :description_text, :stored => true do 
      description 
    end
    text :accession_text, :stored => true do
      accession
    end
    text :sequence_type_text, :stored => true do
      sequence_type
    end
    text :sequence_name_text, :stored => true do
      sequence_name
    end
    text :species_name_text, :stored => true do
     taxon_version.species.scientific_name.name rescue 'No Species'
    end
    text :taxon_name_text, :stored => true do
     taxon_version.taxon.scientific_name.name rescue 'No Taxon'
    end
    text :taxon_version_name_text, :stored => true do
     taxon_version.name
    end
    text :version_text, :stored => true do 
     taxon_version.version
    end
    string :description, :stored => true
    string :accession, :stored => true
    string :sequence_type, :stored => true
    string :sequence_name, :stored => true
    string :species_name, :stored => true do
      taxon_version.species.scientific_name.name rescue 'No Species'
    end
    string :taxon_name, :stored => true do
      taxon_version.taxon.scientific_name.name rescue 'No Taxon'
    end
    string :taxon_version_name, :stored => true do
      taxon_version.name
    end
    string :version, :stored => true do 
      taxon_version.version
    end
    string :taxon_version_type do 
      taxon_version.type
    end
    string :division
    integer :species_id do 
      taxon_version.species_id
    end
    integer :taxon_id do
      taxon_version.taxon_id
    end
    integer :id, :stored => true
    integer :length, :stored => true
    integer :taxon_version_id
    
    integer :biodatabase_id
  end
  
  ## Class Methods

  def self.all_taxon
    TaxonVersion.all.collect(&:taxon).uniq
  end
  
  def self.all_species
    Bioentry.includes(:taxon).all.collect(&:taxon).uniq.collect(&:species).uniq
  end
  
  # Convenience method for Re-indexing a subset of features
  def self.reindex_all_by_id(bioentry_ids,batch_size=100)
    puts "Re-indexing #{bioentry_ids.length} entries"
    progress_bar = ProgressBar.new(bioentry_ids.length)
    bioentry_ids.each_slice(100) do |id_batch|
      Sunspot.index Bioentry.includes([[:bioentry_qualifier_values, :taxon_version => [:species => :scientific_name]], [:source_features => [:qualifiers => :term]]]).where{bioentry_id.in(my{id_batch})}
      Sunspot.commit
      progress_bar.increment!(id_batch.length)
    end
    Sunspot.commit
  end
  ## Instance Methods
  
  # initializes tracks creating any that do not exist. Returns an array of new tracks
  def create_tracks
    result = []
    result << create_models_track if models_track.nil?
    result << create_six_frame_track if six_frame_track.nil?
    #result << create_protein_sequence_track if protein_sequence_track.nil?
    result << create_generic_feature_track if generic_feature_track.nil?    
    return result
  end
  # returns the length of associated biosequence
  def length
    Biosequence.find_by_bioentry_id(self.id,:select => :length).length
  end
  # returns all bioentry qualifiers
  def qualifiers
    self.bioentry_qualifier_values
  end
  # returns species, version info (may include a taxon), and sequence label
  def display_info
    "#{species_name} #{version_info} : #{display_name}"
  end
  # returns taxon name if present version
  def version_info
    "#{taxon_version.species_id==taxon_version.taxon_id ? '' : " > "+taxon_version.name} - #{taxon_version.version}"
  end
  # returns sequence label
  def display_name
    if generic_label_type.empty?
      sequence_name
    else
      "#{generic_label_type}(#{sequence_name})"
    end
  end
  # returns name from source feature to use as sequence label. i.e 1,2,C
  def sequence_name
    # Use accession if missing source or 'unknown' chromosome name
    if source_features.empty? || source_features[0].generic_label.downcase == 'unknown'
      accession
    else 
      source_features[0].generic_label
    end
  end
  # TODO: deprecate in favor of sequence_name
  def short_name
    sequence_name
  end
  # TODO: deprecate in favor of sequence_name
  def generic_label
    # NOTE: we usually only have one source, is it possible to have more than one?
    sequence_name
  end
  # returns type from source feature for sequence label. i.e. Chr, organelle or blank string if unknown
  def sequence_type
    source_features[0].generic_label_type
  end
  # TODO: deprecate in favor of sequence_type
  def generic_label_type
    sequence_type
  end
  # returns the species name. This is the scientific name of the species for associated taxon version
  def species_name
    taxon_version.species.name
  end
  # returns the Taxon representing the superkingdom for associated taxon.
  # the selection is made using the nested set left_value and right_value
  # the nested set must be built or this method will not work correctly
  def superkingdom
    if(taxon.left_value && taxon.right_value)
      Taxon.find(:first, :include => :taxon_names, :conditions => "node_rank='superkingdom' AND left_value < #{taxon.left_value} AND right_value > #{taxon.left_value}")
    else
      nil
    end
  end
  
  def taxon
    taxon_version.nil? ? nil : taxon_version.taxon 
  end
  
  def keywords
    n = []
    bioentry_qualifier_values.each do |q|
      if q.term.name == 'db_xref'
        n<< q
      end
    end
    return n
  end
  
  ['secondary_accession','date_modified'].each do |qv|
   define_method qv.to_sym do
     qualifiers.each do |q|
         if q.term.name == qv
            return q.value
         end
      end
      return nil
    end
  end
  
  def genbank_header
    text = "LOCUS".ljust(12)+accession+"\t#{biosequence.length} bp\t#{biosequence.alphabet}\t#{date_modified}\n"
    text +="DEFINITION".ljust(12)+"#{description}\n"
    text +="ACCESSION".ljust(12)+"#{accession}\n"
    text +="VERSION".ljust(12)+"#{version}\n"
    unless keywords.empty?
      text+="KEYWORDS".ljust(12)+keywords.join(";").break_and_wrap_text(62,"\n",13,false)+"\n"
    end
    text+="SOURCE".ljust(12)+taxon.name+"\n"
    unless comments.empty?
      text+="COMMENT".ljust(12)+comments.map(&:comment_text).join(";").break_and_wrap_text(62,"\n",13,false)+"\n"
    end
    # TODO: Add References
    text+="FEATURES".ljust(21)+"Location/Qualifiers\n"
  end
  
  def to_genbank
    text = genbank_header
    return text
  end
  
  def fasta_header
    ">#{accession} #{description}\n"
  end
  
  def to_fasta
    "#{fasta_header}\n#{biosequence.seq.scan(/.{100}/).join("\n")}"
  end
end



# == Schema Information
#
# Table name: sg_bioentry
#
#  oid         :integer(38)     not null, primary key
#  accession   :string(32)      not null
#  identifier  :string(32)
#  name        :string(32)      not null
#  description :string(512)
#  version     :integer(2)      default(0), not null
#  division    :string(6)       default("UNK")
#  db_oid      :integer(38)     not null
#  tax_oid     :integer(38)
#  deleted_at  :datetime
#  updated_at  :datetime
#

