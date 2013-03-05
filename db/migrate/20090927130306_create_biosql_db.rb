class CreateBiosqlDb < ActiveRecord::Migration 
  # --  This migration helps create a biosql-schema identical to the schema available in biosql-mysql-1.0.1.sql
  # --
  # --  Copyright 2009-2015 Great Lakes Bioenery Research Center
  # --  Copyright 2009-2015 Nick Thrower
  # -- 
  # --  BioSQL is free software: you can redistribute it and/or modify it
  # --  under the terms of the GNU Lesser General Public License as
  # --  published by the Free Software Foundation, either version 3 of the
  # --  License, or (at your option) any later version.
  # --
  # --  BioSQL is distributed in the hope that it will be useful,
  # --  but WITHOUT ANY WARRANTY; without even the implied warranty of
  # --  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  # --  GNU Lesser General Public License for more details.
  # --
  # --  You should have received a copy of the GNU Lesser General Public License
  # --  along with BioSQL. If not, see <http://www.gnu.org/licenses/>
  # --  http://biosql.org/DIST/biosql-1.0.1.tar.gz
  # --  http://www.biosql.org/
  def self.up
    
    create_table :biodatabase, :primary_key => :biodatabase_id do |t|
      t.column :biodatabase_id, :integer, :limit => 10, :null => false
      t.column :name, :string, :limit => 128, :null => false
      t.column :authority, :string, :limit => 128
      t.column :description, :string, :limit => 4000
      t.timestamps
    end
    add_index(:biodatabase, [:name], :unique => true, :name => :biodatabase_idx)
    
    create_table :bioentry, :primary_key => :bioentry_id do |t|
      t.column :bioentry_id, :integer, :limit => 10, :null => false
      t.column :biodatabase_id, :integer, :limit => 10, :null => false
      t.column :taxon_id, :integer, :limit => 10
      t.column :name, :string, :limit => 40, :null => false
      t.column :accession, :string, :limit => 128, :null => false
      t.column :identifier, :string, :limit => 40
      t.column :division, :string, :limit => 6
      t.column :description, :string, :limit => 4000
      t.column :version, :string, :null => false
      t.timestamps
    end
    # We do not set the 'identifier' column so it is not unique
    #add_index(:bioentry, [:taxon_version_id, :identifier, :biodatabase_id, :version], :unique => true, :name => :bioentry_idx_1)
    
    create_table :bioentry_dbxref, :id => false do |t|
      t.column :bioentry_id, :integer, :limit => 10, :null => false
      t.column :dbxref_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer
      t.timestamps
    end
    
    create_table :bioentry_path, :id => false do |t|
      t.column :object_bioentry_id, :integer, :limit => 10, :null => false
      t.column :subject_bioentry_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :distance, :integer, :limit => 10
      t.timestamps
    end
    add_index(:bioentry_path, [:object_bioentry_id, :subject_bioentry_id, :term_id, :distance], :unique => true, :name => :bioentry_path_idx)
    
    
    create_table :bioentry_qualifier_value, :id => false do |t|
      t.column :bioentry_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :value, :string, :limit => 4000
      t.column :rank, :integer, :limit => 5, :default => 0, :null => false
      t.timestamps
    end
    add_index(:bioentry_qualifier_value, [:bioentry_id, :term_id, :rank], :unique => true, :name => :bioentry_qualifier_value_idx)
    
    create_table :bioentry_reference, :id => false do |t|
      t.column :bioentry_id, :integer, :limit => 10, :null => false
      t.column :reference_id, :integer, :limit => 10, :null => false
      t.column :start_pos, :integer, :limit => 10
      t.column :end_pos, :integer, :limit => 10
      t.column :rank, :integer, :default => 0, :null => false
      t.timestamps
    end
    
    create_table :bioentry_relationship, :primary_key => :bioentry_relationship_id do |t|
      t.column :bioentry_relationship_id, :integer, :limit => 10, :null => false
      t.column :object_bioentry_id, :integer, :limit => 10, :null => false
      t.column :subject_bioentry_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer, :limit => 5
      t.timestamps
    end
    add_index(:bioentry_relationship, [:object_bioentry_id, :subject_bioentry_id, :term_id], :unique => true, :name => :bioentry_relationship_idx)
    
    
    create_table :biosequence, :id => false do |t|
      t.column :bioentry_id, :integer, :limit => 10, :null => false
      t.column :version, :integer
      t.column :length, :integer, :limit => 10
      t.column :alphabet, :string, :limit => 10
      if(self.adapter_name.downcase =~/.*mysql.*/) # mysql text column is limited at 2^16
        t.column :seq, :longtext
      else
        t.column :seq, :text
      end
      t.timestamps
    end
    add_index(:biosequence, [:bioentry_id,:version], :unique => true, :name => :bioseq_idx )
    # Comment is a reserved word in oracle
    if(self.adapter_name.downcase =~/.*oracle.*/)
      create_table :comments, :primary_key => :comments_id do |t|
        t.column :comments_id, :integer, :limit => 10, :null => false
        t.column :bioentry_id, :integer, :limit => 10, :null => false
        t.column :comment_text, :text, :null => false
        t.column :rank, :integer, :default => 0, :null => false
        t.timestamps
      end
      add_index(:comments, [:bioentry_id, :rank], :unique => true, :name => :comments_idx)
    else
      create_table :comment, :primary_key => :comment_id do |t|
        t.column :comment_id, :integer, :limit => 10, :null => false
        t.column :bioentry_id, :integer, :limit => 10, :null => false
        t.column :comment_text, :text, :null => false
        t.column :rank, :integer, :default => 0, :null => false
        t.timestamps
      end
      add_index(:comment, [:bioentry_id, :rank], :unique => true, :name => :comment_idx)
    end
    
    create_table :dbxref, :primary_key => :dbxref_id do |t|
      t.column :dbxref_id, :integer, :limit => 10, :null => false
      t.column :dbname, :string, :limit => 40, :null => false
      t.column :accession, :string, :limit => 128, :null => false
      t.column :version, :integer, :null => false
      t.timestamps
    end
    add_index(:dbxref, [:accession, :dbname, :version], :unique => true, :name => :dbxref_idx)
    
    create_table :dbxref_qualifier_value, :id => false do |t|
      t.column :dbxref_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer, :default => 0, :null => false
      t.column :value, :string, :limit => 4000
      t.timestamps
    end
    
    create_table :location, :primary_key => :location_id do |t|
      t.column :location_id, :integer, :limit => 10, :null => false
      t.column :seqfeature_id, :integer, :limit => 10, :null => false
      t.column :dbxref_id, :integer, :limit => 10
      t.column :term_id, :integer, :limit => 10
      t.column :start_pos, :integer, :limit => 10
      t.column :end_pos, :integer, :limit => 10
      t.column :strand, :integer, :default => 0, :null => false
      t.column :rank, :integer, :default => 0, :null => false
      t.timestamps
    end
    add_index(:location, [:seqfeature_id, :rank], :unique => true, :name => :location_idx)
    add_index(:location, [:seqfeature_id], :name => :location_idx_1)
    
    create_table :location_qualifier_value, :id => false do |t|
      t.column :location_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :value, :string, :limit => 255, :null => false
      t.column :int_value, :integer, :limit => 10
      t.timestamps
    end
    
    create_table :ontology, :primary_key => :ontology_id do |t|
      t.column :ontology_id, :integer, :limit => 10, :null => false
      t.column :name, :string, :limit => 32, :null => false
      t.column :definition, :string, :limit => 4000
      t.timestamps
    end
    add_index(:ontology, [:name], :unique => true, :name => :ontology_idx)
    
    create_table :reference, :primary_key => :reference_id do |t|
      t.column :reference_id, :integer, :limit => 10, :null => false
      t.column :dbxref_id, :integer, :limit => 10
      t.column :location, :string, :limit => 4000, :null => false
      t.column :title, :string, :limit => 4000
      t.column :authors, :string, :limit => 4000
      t.column :crc, :string, :limit => 32
      t.timestamps
    end
    add_index(:reference, [:dbxref_id], :unique => true, :name => :reference_idx)
    add_index(:reference, [:crc], :unique => true, :name => :reference_idx_1)
    
    create_table :seqfeature, :primary_key => :seqfeature_id do |t|
      t.column :seqfeature_id, :integer, :limit => 10, :null => false
      t.column :bioentry_id, :integer, :limit => 10, :null => false
      t.column :type_term_id, :integer, :limit => 10, :null => false
      t.column :source_term_id, :integer, :limit => 10, :null => false
      t.column :display_name, :string, :limit => 64
      t.column :rank, :integer, :default => 0, :null => false
      t.timestamps
    end
    add_index(:seqfeature, [:bioentry_id, :type_term_id, :source_term_id, :rank], :unique => true, :name => :seqfeature_idx)
    add_index(:seqfeature, [:display_name], :name => :seqfeature_idx_1)
    
    create_table :seqfeature_dbxref, :id => false do |t|
      t.column :seqfeature_id, :integer, :limit => 10, :null => false
      t.column :dbxref_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer
      t.timestamps
    end
    
    create_table :seqfeature_path, :id => false do |t|
      t.column :object_seqfeature_id, :integer, :limit => 10, :null => false
      t.column :subject_seqfeature_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :distance, :integer, :limit => 10
      t.timestamps
    end
    add_index(:seqfeature_path, [:object_seqfeature_id, :subject_seqfeature_id, :term_id, :distance], :unique => true, :name => :seqfeature_path_idx)
    
    create_table :seqfeature_qualifier_value, :id => false do |t|
      t.column :seqfeature_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer, :default => 0, :null => false
      t.column :value, :string, :limit => 4000, :null => false
      t.timestamps
    end
    add_index(:seqfeature_qualifier_value, [:seqfeature_id], :name => :sqv_idx)
    add_index(:seqfeature_qualifier_value, [:term_id], :name => :sqv_idx_1)
    add_index(:seqfeature_qualifier_value, [:seqfeature_id, :term_id, :rank], :unique => :true, :name => :sqv_idx_2)
    add_index(:seqfeature_qualifier_value, :value, :name => :sqv_idx_3)
    
    
    create_table :seqfeature_relationship, :primary_key => :seqfeature_relationship_id do |t|
      t.column :seqfeature_relationship_id, :integer, :limit => 10, :null => false
      t.column :object_seqfeature_id, :integer, :limit => 10, :null => false
      t.column :subject_seqfeature_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer, :limit => 5
      t.timestamps
    end
    add_index(:seqfeature_relationship, [:object_seqfeature_id, :subject_seqfeature_id, :term_id], :unique => true, :name => :seqfeature_relationship_idx)    
    
    create_table :taxon, :primary_key => :taxon_id do |t|
      t.column :taxon_id, :integer, :limit => 10, :null => false
      t.column :ncbi_taxon_id, :integer, :limit => 10
      t.column :parent_taxon_id, :integer, :limit => 10
      t.column :node_rank, :string, :limit => 32
      t.column :genetic_code, :integer
      t.column :mito_genetic_code, :integer
      t.column :left_value, :integer, :limit => 10
      t.column :right_value, :integer, :limit => 10
      t.timestamps
    end
    add_index(:taxon, [:ncbi_taxon_id], :unique => true, :name => :taxon_idx)
    add_index(:taxon, [:left_value], :unique => true, :name => :taxon_idx_1)
    add_index(:taxon, [:right_value], :unique => true, :name => :taxon_idx_2)
    
    create_table :taxon_name, :id => false do |t|
      t.column :taxon_id, :integer, :limit => 10, :null => false
      t.column :name, :string, :limit => 255, :null => false
      t.column :name_class, :string, :limit => 32, :null => false
      t.timestamps
    end
    add_index(:taxon_name, [:taxon_id, :name, :name_class], :unique => true, :name => :taxon_name_idx)
    
    create_table :term, :primary_key => :term_id do |t|
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :name, :string, :limit => 255, :null => false
      t.column :definition, :string, :limit => 4000
      t.column :identifier, :string, :limit => 40
      t.column :is_obsolete, :string, :limit => 1
      t.column :ontology_id, :integer, :limit => 10, :null => false
      t.timestamps
    end
    #add_index(:term, [:identifier], :unique => true, :name => :term_idx)
    add_index(:term, [:name, :ontology_id, :is_obsolete], :unique => true, :name => :term_idx_1)
    add_index(:term, [:name], :name => :term_idx_2)
    
    create_table :term_dbxref, :id => false do |t|
      t.column :term_id, :integer, :limit => 10, :null => false
      t.column :dbxref_id, :integer, :limit => 10, :null => false
      t.column :rank, :integer
      t.timestamps
    end
    
    create_table :term_path, :primary_key => :term_path_id do |t|
      t.column :term_path_id, :integer, :limit => 10, :null => false
      t.column :subject_term_id, :integer, :limit => 10, :null => false
      t.column :predicate_term_id, :integer, :limit => 10, :null => false
      t.column :object_term_id, :integer, :limit => 10, :null => false
      t.column :ontology_id, :integer, :limit => 10, :null => false
      t.column :distance, :integer, :limit => 10
      t.timestamps
    end
    add_index(:term_path, [:subject_term_id, :predicate_term_id, :object_term_id, :ontology_id, :distance], :unique => true, :name => :term_path_idx)
    
    create_table :term_relationship, :primary_key => :term_relationship_id do |t|
      t.column :term_relationship_id, :integer, :limit => 10, :null => false
      t.column :subject_term_id, :integer, :limit => 10, :null => false
      t.column :predicate_term_id, :integer, :limit => 10, :null => false
      t.column :object_term_id, :integer, :limit => 10, :null => false
      t.column :ontology_id, :integer, :limit => 10, :null => false
      t.timestamps
    end
    add_index(:term_relationship, [:subject_term_id, :predicate_term_id, :object_term_id, :ontology_id], :unique => true, :name => :term_relationship_idx)
    
    
    create_table :term_relationship_term, :id => false do |t|
      t.column :term_relationship_id, :integer, :limit => 10, :null => false
      t.column :term_id, :integer, :limit => 10, :null => false
      t.timestamps
    end
    add_index(:term_relationship_term, [:term_id], :unique => true, :name => :term_relationship_term_idx)
    
    create_table :term_synonym, :id => false do |t|
      # synonym is a reserved word in oracle.
      if(self.adapter_name.downcase =~/.*oracle.*/)
        t.column :ora_synonym, :string, :limit => 255, :null => false
      else
        t.column :synonym, :string, :limit => 255, :null => false
      end
      t.column :term_id, :integer, :limit => 10, :null => false
      t.timestamps
    end

  end

  def self.down
    # Comment is a reserved word in oracle.
    if(self.adapter_name.downcase =~/.*oracle.*/)
      drop_table :comments
    else
      drop_table :comment
    end
    drop_table :biodatabase
    drop_table :location_qualifier_value
    drop_table :taxon
    drop_table :location
    drop_table :taxon_name
    drop_table :seqfeature_dbxref
    drop_table :ontology
    drop_table :seqfeature_qualifier_value
    drop_table :term
    drop_table :seqfeature_path
    drop_table :term_synonym
    drop_table :seqfeature_relationship
    drop_table :term_dbxref
    drop_table :seqfeature
    drop_table :term_relationship
    drop_table :bioentry_qualifier_value
    drop_table :term_relationship_term
    drop_table :term_path
    drop_table :bioentry_reference
    drop_table :bioentry
    drop_table :reference
    drop_table :bioentry_relationship
    drop_table :bioentry_dbxref
    drop_table :bioentry_path
    drop_table :dbxref_qualifier_value
    drop_table :biosequence
    drop_table :dbxref
  end
end