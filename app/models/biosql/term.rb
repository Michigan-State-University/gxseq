class Term < ActiveRecord::Base
  set_primary_key :term_id
  set_table_name "term"
  belongs_to :type_term, :class_name => "Term", :foreign_key => "type_term_id"
  belongs_to :source_term, :class_name => "Term", :foreign_key => "source_term_id"
  belongs_to :ontology, :class_name => "Ontology"
  has_one :location, :class_name  => "Location"
  if(note = Term.find_by_name("note"))
    has_many :notes, :class_name => "SeqfeatureQualifierValue", :order => "rank", :conditions => "term_id = #{note.id}"
  end
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
  
  def self.annotation_tags
    if( o = Ontology.find_by_name("Annotation Tags"))
      return Term.where(:ontology_id => o.id)
    else
      return nil
    end
  end
  
  def self.denormalize
    begin
      puts "Updating Location -> term_id"
      Term.connection.execute("update location set term_id = (select seqfeature.type_term_id from seqfeature where seqfeature.seqfeature_id = location.seqfeature_id)")      
      puts "Updating Seqfeature -> display_name"
      Term.transaction do
        terms = {}
        Term.all.each do |term|
          terms[term.term_id.to_s]=term.name.downcase.camelize
        end
        Seqfeature.connection.select_all("SELECT seqfeature_id, type_term_id FROM seqfeature").each do |feature|
          Seqfeature.connection.execute("UPDATE seqfeature set display_name = '#{terms[feature["type_term_id"].to_s]}' where seqfeature_id = #{feature["seqfeature_id"]}")
        end
      end
      puts "Done"
      return true
    rescue
      puts $!
      return false
    end
  end
   
  def display_name
    name
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

