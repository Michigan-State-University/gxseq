class Biosql::Term < ActiveRecord::Base
  set_primary_key :term_id
  set_table_name "term"
  belongs_to :ontology, :class_name => "Ontology"
  has_one :location, :class_name  => "Location"
  has_many :qualifiers, :class_name => "SeqfeatureQualifierValue", :order  => "term_id, rank"
  has_many :dbxref_qualifier_values, :class_name => "DbxrefQualifierValue"
  has_many :bioentry_qualifer_values, :class_name => "BioentryQualifierValue"
  has_many :bioentries, :through=>:bioentry_qualifier_values
  has_many :locations, :class_name => "Location", :order  => "start_pos asc"
  has_many :seqfeature_relationships, :class_name => "SeqfeatureRelationship"
  has_many :term_dbxrefs, :class_name => "TermDbxref"
  has_many :term_relationship_terms, :class_name => "TermRelationshipTerm"
  has_many :term_synonyms, :class_name => "TermSynonym"
  has_many :location_qualifier_values, :class_name => "LocationQualifierValue"
  has_many :seqfeature_types, :class_name => "Seqfeature", :foreign_key => "type_term_id"
  has_many :seqfeature_sources, :class_name => "Seqfeature", :foreign_key => "source_term_id"
  has_many :term_path_subjects, :class_name => "TermPath", :foreign_key => "subject_term_id"
  has_many :term_path_predicates, :class_name => "TermPath", :foreign_key => "predicate_term_id"
  has_many :term_path_objects, :class_name => "TermPath", :foreign_key => "object_term_id"
  has_many :term_relationship_subjects, :class_name => "TermRelationship", :foreign_key =>"subject_term_id"
  has_many :term_relationship_predicates, :class_name => "TermRelationship", :foreign_key =>"predicate_term_id"
  has_many :term_relationship_objects, :class_name => "TermRelationship", :foreign_key =>"object_term_id"
  has_many :seqfeature_paths, :class_name => "SeqfeaturePath"
  ## CLASS METHODS
  # ontology terms
  def self.annotation_tags
    self.where(:ontology_id => ano_tag_ont_id)
  end
  def self.source_tags
    self.where(:ontology_id => seq_src_ont_id)
  end
  def self.seqfeature_tags
    self.where(:ontology_id => seq_key_ont_id)
  end
  # Default ontology setup
  def self.seq_src_ont_id
    @seq_src_id ||= Biosql::Ontology.find_or_create_by_name("SeqFeature Sources").try(:id)
  end
  def self.seq_key_ont_id
    @seq_key_id ||= Biosql::Ontology.find_or_create_by_name("SeqFeature Keys").try(:id)
  end
  def self.ano_tag_ont_id
    @ano_tag_id ||= Biosql::Ontology.find_or_create_by_name("Annotation Tags").try(:id)
  end
  # All but seqfeature source and seqfeature keys
  def self.annotation_ontologies
    @anno_ont ||= Biosql::Ontology.where("ontology_id not in(#{seq_src_ont_id},#{seq_key_ont_id})").order("name desc")
  end
  # All non standard ontologies
  def self.custom_ontologies
    @custom_ont ||= Biosql::Ontology.where("ontology_id not in(#{seq_src_ont_id},#{seq_key_ont_id},#{ano_tag_ont_id})")
  end
  # returns the default source term for use with seqfeature source_term
  def self.default_source_term
    @default_src_tm ||= self.find_or_create_by_name_and_ontology_id("EMBL/GenBank/SwissProt",seq_src_ont_id)
  end
  
  def self.denormalize
    begin
      puts "Updating Location -> term_id"
      self.connection.execute("update location set term_id = (select seqfeature.type_term_id from seqfeature where seqfeature.seqfeature_id = location.seqfeature_id) where term_id is null")      
      puts "Updating Seqfeature -> display_name"
      self.transaction do
        Biosql::Feature::Seqfeature.where('display_name is null').includes(:type_term).each do |feature|
          feature.update_attribute(:display_name,feature.type_term.name.downcase.camelize)
        end
      end
      puts "Done"
      return true
    rescue
      puts $!
      return false
    end
  end
end



# == Schema Information
#
# Table name: sg_term
#
#  oid         :integer(38)     not null, primary key
#  name        :string(256)     not null
#  identifier  :string(16)
#  definition  :string(4000)
#  is_obsolete :string(1)
#  ont_oid     :integer(38)     not null
#  deleted_at  :datetime
#  updated_at  :datetime
#

