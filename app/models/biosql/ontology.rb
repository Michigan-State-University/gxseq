# == Schema Information
#
# Table name: ontology
#
#  created_at  :datetime
#  definition  :string(4000)
#  name        :string(32)       not null
#  ontology_id :integer          not null, primary key
#  updated_at  :datetime
#

class Biosql::Ontology < ActiveRecord::Base
  set_table_name "ontology"
  set_primary_key :ontology_id
  has_many :terms, :class_name => "Biosql::Term", :order => 'name asc'
  has_many :term_paths, :class_name => "TermPath"
  has_many :term_relationships, :class_name => "TermRelationship"
end
