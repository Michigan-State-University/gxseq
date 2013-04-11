class Bio::Ontology < ActiveRecord::Base
  set_table_name "ontology"
  set_primary_key :ontology_id
  has_many :terms, :class_name => "Term", :order => 'name asc'
  has_many :term_paths, :class_name => "TermPath"
  has_many :term_relationships, :class_name => "TermRelationship"
end



# == Schema Information
#
# Table name: sg_ontology
#
#  oid        :integer(38)     not null, primary key
#  name       :string(64)      not null
#  definition :string(4000)
#  updated_at :datetime
#  deleted_at :datetime
#

