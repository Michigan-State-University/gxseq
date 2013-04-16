class Biosql::Dbxref < ActiveRecord::Base
  set_table_name "dbxref"
  set_primary_key :dbxref_id
  has_many :dbxref_qualifier_values, :class_name => "DbxrefQualifierValue"
  has_many :locations, :class_name => "Location"
  has_many :references, :class_name=>"Reference"
  has_many :term_dbxrefs, :class_name => "TermDbxref"
  has_many :bioentry_dbxrefs, :class_name => "BioentryDbxref"
  
  def display_info
    "#{dbname}:<a href='#{XREF_LINKS[dbname.underscore.to_sym]}#{accession}' target=#>#{accession}</a>"
  end

  XREF_LINKS = {
    :pubmed => "http://www.ncbi.nlm.nih.gov/pubmed?term=",
    :pmid => "http://www.ncbi.nlm.nih.gov/pubmed?term=",
    :taxon => "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=",
    :tair => "http://arabidopsis.org/servlets/TairObject?type=locus&name=",
    :geneid => "http://www.ncbi.nlm.nih.gov/gene?term=",
    :gi => "http://www.ncbi.nlm.nih.gov/nuccore/",
    :sgd => "http://www.yeastgenome.org/cgi-bin/locus.fpl?locus="
  }
  
end

# == Schema Information
#
# Table name: sg_dbxref
#
#  oid       :integer(38)     not null, primary key
#  dbname    :string(32)      not null
#  accession :string(64)      not null
#  version   :integer(2)      default(0), not null
#

