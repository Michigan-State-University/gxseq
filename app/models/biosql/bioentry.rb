class Bioentry < ActiveRecord::Base
  set_table_name "bioentry"
  set_primary_key :bioentry_id
  belongs_to :biodatabase, :class_name => "Biodatabase"
  belongs_to :taxon_version
  
  has_one :biosequence, :dependent  => :destroy
  
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
  has_many :experiments, :through => :bioentries_experiments, :dependent  => :destroy
  has_many :chip_seqs, :through => :bioentries_experiments
  has_many :chip_chips, :through => :bioentries_experiments
  has_many :synthetics, :through => :bioentries_experiments
  has_many :variants, :through => :bioentries_experiments
  has_many :tracks, :dependent => :destroy
  has_many :peaks
  
  has_one :models_track
  has_one :six_frame_track
  has_one :protein_sequence_track
  has_one :generic_feature_track
  
  
  scope :with_version, lambda { |v| where("version = ?",v) }
  has_paper_trail :version_method_name => 'reified_version'
  acts_as_api
  
  ## Class Methods
  
  def self.all_taxon
    #Bioentry.includes(:taxon).all.collect(&:taxon).uniq
    Taxon.joins(:bioentries).select("distinct #{Taxon.table_name}.taxon_id,version")
  end
  
  def self.all_species
    Bioentry.includes(:taxon).all.collect(&:taxon).uniq.collect(&:species).uniq
  end
  
  
  ## Instance Methods
  
  # initalizing tracks after creation
  def create_tracks
    result = []
    result << create_models_track if models_track.nil?
    result << create_six_frame_track if six_frame_track.nil?
    #result << create_protein_sequence_track if protein_sequence_track.nil?
    result << create_generic_feature_track if generic_feature_track.nil?    
    return result
  end
  
  # convenience methods
  def length
    biosequence.length
  end
  
  def qualifiers
    self.bioentry_qualifier_values
  end
  
  def display_info
    "#{species_name} #{taxon_version.species_id==taxon_version.taxon_id ? '' : " > "+taxon_version.name} - #{version} : #{generic_label_type}(#{generic_label})"
  end
  
  def display_name
    "#{ generic_label_type}(#{generic_label})"
  end
  
  def short_name
    generic_label
  end
  
  def generic_label
    source_features.empty? ? accession : source_features[0].generic_label
  end
  
  def generic_label_type
    source_features.empty? ? 'contig' : source_features[0].generic_label_type
  end
  
  def species_name
    taxon_version.species.name
  end
  
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
    text+="FEATURES".ljust(21)+"Location/Qualifiers"
  end
  
  def to_genbank
    text = genbank_header    
    return text
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

