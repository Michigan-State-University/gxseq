# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121219213926) do

  create_table "assets", :force => true do |t|
    t.string   "type"
    t.integer  "experiment_id"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.string   "state",             :default => "pending"
    t.integer  "data_file_size"
    t.datetime "data_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "biodatabase", :primary_key => "biodatabase_id", :force => true do |t|
    t.string   "name",        :limit => 128,  :null => false
    t.string   "authority",   :limit => 128
    t.string   "description", :limit => 4000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "biodatabase", ["name"], :name => "biodatabase_idx", :unique => true

  create_table "biodatabases_taxons", :id => false, :force => true do |t|
    t.integer "biodatabase_id"
    t.integer "taxon_id"
  end

  create_table "bioentries_experiments", :force => true do |t|
    t.integer  "bioentry_id"
    t.integer  "experiment_id"
    t.string   "sequence_name"
    t.decimal  "abs_max",       :precision => 15, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bioentry", :primary_key => "bioentry_id", :force => true do |t|
    t.integer  "biodatabase_id",                   :null => false
    t.integer  "taxon_version_id",                 :null => false
    t.string   "name",             :limit => 40,   :null => false
    t.string   "accession",        :limit => 128,  :null => false
    t.string   "identifier",       :limit => 40
    t.string   "division",         :limit => 6
    t.string   "description",      :limit => 4000
    t.string   "version",                          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "taxon_id"
  end

  add_index "bioentry", ["accession", "biodatabase_id", "version"], :name => "bioentry_idx", :unique => true
  add_index "bioentry", ["identifier", "biodatabase_id", "version"], :name => "bioentry_idx_1", :unique => true
  add_index "bioentry", ["version"], :name => "bioentry_idx_2"

  create_table "bioentry_dbxref", :id => false, :force => true do |t|
    t.integer  "bioentry_id", :null => false
    t.integer  "dbxref_id",   :null => false
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bioentry_path", :id => false, :force => true do |t|
    t.integer  "object_bioentry_id",  :null => false
    t.integer  "subject_bioentry_id", :null => false
    t.integer  "term_id",             :null => false
    t.integer  "distance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry_path", ["object_bioentry_id", "subject_bioentry_id", "term_id", "distance"], :name => "bioentry_path_idx", :unique => true

  create_table "bioentry_qualifier_value", :id => false, :force => true do |t|
    t.integer  "bioentry_id",                                :null => false
    t.integer  "term_id",                                    :null => false
    t.string   "value",       :limit => 4000
    t.integer  "rank",        :limit => 8,    :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry_qualifier_value", ["bioentry_id", "term_id", "rank"], :name => "bioentry_qualifier_value_idx", :unique => true

  create_table "bioentry_reference", :id => false, :force => true do |t|
    t.integer  "bioentry_id",                 :null => false
    t.integer  "reference_id",                :null => false
    t.integer  "start_pos"
    t.integer  "end_pos"
    t.integer  "rank",         :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bioentry_relationship", :primary_key => "bioentry_relationship_id", :force => true do |t|
    t.integer  "object_bioentry_id",               :null => false
    t.integer  "subject_bioentry_id",              :null => false
    t.integer  "term_id",                          :null => false
    t.integer  "rank",                :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry_relationship", ["object_bioentry_id", "subject_bioentry_id", "term_id"], :name => "bioentry_relationship_idx", :unique => true

  create_table "biosequence", :id => false, :force => true do |t|
    t.integer  "bioentry_id",                       :null => false
    t.integer  "version"
    t.integer  "length"
    t.string   "alphabet",    :limit => 10
    t.text     "seq",         :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blast_databases", :force => true do |t|
    t.string   "name"
    t.string   "abbreviation"
    t.string   "link_ref"
    t.string   "description"
    t.string   "taxon_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blast_reports", :force => true do |t|
    t.integer  "seqfeature_id", :null => false
    t.integer  "blast_run_id",  :null => false
    t.text     "report"
    t.string   "hit_acc"
    t.string   "hit_def"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blast_runs", :force => true do |t|
    t.integer "blast_database_id"
    t.integer "taxon_version_id"
    t.text    "parameters"
    t.string  "program"
    t.string  "version"
    t.string  "reference"
    t.string  "db"
  end

  create_table "comment", :primary_key => "comment_id", :force => true do |t|
    t.integer  "bioentry_id",                 :null => false
    t.text     "comment_text",                :null => false
    t.integer  "rank",         :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comment", ["bioentry_id", "rank"], :name => "comment_idx", :unique => true

  create_table "components", :force => true do |t|
    t.string   "type"
    t.integer  "experiment_id"
    t.integer  "synthetic_experiment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "console_logs", :force => true do |t|
    t.integer  "loggable_id"
    t.string   "loggable_type"
    t.text     "console"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dbxref", :primary_key => "dbxref_id", :force => true do |t|
    t.string   "dbname",     :limit => 40,  :null => false
    t.string   "accession",  :limit => 128, :null => false
    t.integer  "version",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dbxref", ["accession", "dbname", "version"], :name => "dbxref_idx", :unique => true

  create_table "dbxref_qualifier_value", :id => false, :force => true do |t|
    t.integer  "dbxref_id",                                 :null => false
    t.integer  "term_id",                                   :null => false
    t.integer  "rank",                       :default => 0, :null => false
    t.string   "value",      :limit => 4000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",     :default => 0
    t.integer  "attempts",     :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
    t.integer  "user_id"
    t.datetime "completed_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "experiments", :force => true do |t|
    t.integer  "bioentry_id"
    t.integer  "user_id"
    t.string   "name"
    t.string   "type"
    t.string   "description"
    t.string   "file_name"
    t.string   "a_op"
    t.string   "b_op"
    t.string   "mid_op"
    t.string   "sequence_name"
    t.string   "state"
    t.string   "show_negative"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "taxon_version_id"
    t.integer  "group_id"
  end

  create_table "favorites", :force => true do |t|
    t.integer  "user_id"
    t.string   "type"
    t.integer  "favorite_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feature_counts", :force => true do |t|
    t.integer  "seqfeature_id"
    t.integer  "experiment_id"
    t.integer  "count"
    t.decimal  "normalized_count", :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gene_models", :force => true do |t|
    t.string  "transcript_id"
    t.string  "protein_id"
    t.integer "variants"
    t.string  "locus_tag"
    t.string  "gene_name"
    t.integer "start_pos"
    t.integer "end_pos"
    t.integer "strand"
    t.integer "rank"
    t.integer "gene_id"
    t.integer "cds_id"
    t.integer "mrna_id"
    t.integer "bioentry_id"
  end

  add_index "gene_models", ["bioentry_id"], :name => "gene_models_idx_3"
  add_index "gene_models", ["cds_id"], :name => "gene_models_idx_1"
  add_index "gene_models", ["gene_id"], :name => "gene_models_idx"
  add_index "gene_models", ["mrna_id"], :name => "gene_models_idx_2"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  create_table "location", :primary_key => "location_id", :force => true do |t|
    t.integer  "seqfeature_id",                :null => false
    t.integer  "dbxref_id"
    t.integer  "term_id"
    t.integer  "start_pos"
    t.integer  "end_pos"
    t.integer  "strand",        :default => 0, :null => false
    t.integer  "rank",          :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "location", ["seqfeature_id", "rank"], :name => "location_idx", :unique => true
  add_index "location", ["seqfeature_id"], :name => "location_idx_1"

  create_table "location_qualifier_value", :id => false, :force => true do |t|
    t.integer  "location_id", :null => false
    t.integer  "term_id",     :null => false
    t.string   "value",       :null => false
    t.integer  "int_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ontology", :primary_key => "ontology_id", :force => true do |t|
    t.string   "name",       :limit => 32,   :null => false
    t.string   "definition", :limit => 4000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ontology", ["name"], :name => "ontology_idx", :unique => true

  create_table "peaks", :force => true do |t|
    t.integer  "experiment_id"
    t.integer  "bioentry_id"
    t.integer  "start_pos"
    t.integer  "end_pos"
    t.float    "val"
    t.integer  "pos"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "owner_id",   :null => false
    t.string   "owner_type", :null => false
    t.integer  "group_id"
    t.string   "group_type"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["owner_id", "owner_type", "name", "group_id", "group_type"], :name => "owner_name_group_pref_idx", :unique => true

  create_table "reference", :primary_key => "reference_id", :force => true do |t|
    t.integer  "dbxref_id"
    t.string   "location",   :limit => 4000, :null => false
    t.string   "title",      :limit => 4000
    t.string   "authors",    :limit => 4000
    t.string   "crc",        :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reference", ["crc"], :name => "reference_idx_1", :unique => true
  add_index "reference", ["dbxref_id"], :name => "reference_idx", :unique => true

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "seqfeature", :primary_key => "seqfeature_id", :force => true do |t|
    t.integer  "bioentry_id",                                 :null => false
    t.integer  "type_term_id",                                :null => false
    t.integer  "source_term_id",                              :null => false
    t.string   "display_name",   :limit => 64
    t.integer  "rank",                         :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature", ["bioentry_id", "type_term_id", "source_term_id", "rank"], :name => "seqfeature_idx", :unique => true
  add_index "seqfeature", ["display_name"], :name => "seqfeature_idx_1"

  create_table "seqfeature_dbxref", :id => false, :force => true do |t|
    t.integer  "seqfeature_id", :null => false
    t.integer  "dbxref_id",     :null => false
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "seqfeature_path", :id => false, :force => true do |t|
    t.integer  "object_seqfeature_id",  :null => false
    t.integer  "subject_seqfeature_id", :null => false
    t.integer  "term_id",               :null => false
    t.integer  "distance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature_path", ["object_seqfeature_id", "subject_seqfeature_id", "term_id", "distance"], :name => "seqfeature_path_idx", :unique => true

  create_table "seqfeature_qualifier_value", :id => false, :force => true do |t|
    t.integer  "seqfeature_id",                                :null => false
    t.integer  "term_id",                                      :null => false
    t.integer  "rank",                          :default => 0, :null => false
    t.string   "value",         :limit => 4000,                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature_qualifier_value", ["seqfeature_id", "term_id", "rank"], :name => "seqfeature_id_2", :unique => true
  add_index "seqfeature_qualifier_value", ["seqfeature_id", "term_id", "value"], :name => "seqfeature_id", :unique => true, :length => {"seqfeature_id"=>nil, "term_id"=>nil, "value"=>100}
  add_index "seqfeature_qualifier_value", ["term_id"], :name => "sqv_idx_1"
  add_index "seqfeature_qualifier_value", ["value"], :name => "sqv_idx_3", :length => {"value"=>255}

  create_table "seqfeature_relationship", :primary_key => "seqfeature_relationship_id", :force => true do |t|
    t.integer  "object_seqfeature_id",               :null => false
    t.integer  "subject_seqfeature_id",              :null => false
    t.integer  "term_id",                            :null => false
    t.integer  "rank",                  :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature_relationship", ["object_seqfeature_id", "subject_seqfeature_id", "term_id"], :name => "seqfeature_relationship_idx", :unique => true

  create_table "sequence_files", :force => true do |t|
    t.string   "type"
    t.integer  "bioentry_id"
    t.integer  "version"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "data_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sequence_variants", :force => true do |t|
    t.integer  "experiment_id"
    t.integer  "bioentry_id"
    t.integer  "pos"
    t.string   "ref"
    t.string   "alt"
    t.integer  "qual"
    t.float    "frequency"
    t.string   "type"
    t.integer  "depth"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sequence_variants", ["experiment_id", "bioentry_id", "pos"], :name => "seq_variant_idx_2"
  add_index "sequence_variants", ["experiment_id", "bioentry_id"], :name => "seq_variant_idx_1"
  add_index "sequence_variants", ["experiment_id", "pos"], :name => "seq_variant_idx"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taxon", :primary_key => "taxon_id", :force => true do |t|
    t.integer  "ncbi_taxon_id"
    t.integer  "parent_taxon_id"
    t.string   "node_rank",         :limit => 32
    t.integer  "genetic_code"
    t.integer  "mito_genetic_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "left_value"
    t.integer  "right_value"
    t.integer  "non_ncbi",                        :default => 0
  end

  add_index "taxon", ["ncbi_taxon_id"], :name => "taxon_idx", :unique => true
  add_index "taxon", ["node_rank"], :name => "node_rank_idx"

  create_table "taxon_name", :id => false, :force => true do |t|
    t.integer  "taxon_id",                 :null => false
    t.string   "name",                     :null => false
    t.string   "name_class", :limit => 32, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taxon_name", ["name"], :name => "taxon_name_idx2"
  add_index "taxon_name", ["taxon_id", "name", "name_class"], :name => "taxon_name_idx", :unique => true

  create_table "taxon_versions", :force => true do |t|
    t.integer  "taxon_id"
    t.integer  "species_id"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "group_id"
  end

  add_index "taxon_versions", ["version"], :name => "index_taxon_versions_on_version", :unique => true

  create_table "term", :primary_key => "term_id", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "definition",  :limit => 4000
    t.string   "identifier",  :limit => 40
    t.string   "is_obsolete", :limit => 1
    t.integer  "ontology_id",                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term", ["name", "ontology_id", "is_obsolete"], :name => "term_idx_1", :unique => true
  add_index "term", ["name"], :name => "term_idx_2"

  create_table "term_dbxref", :id => false, :force => true do |t|
    t.integer  "term_id",    :null => false
    t.integer  "dbxref_id",  :null => false
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "term_path", :primary_key => "term_path_id", :force => true do |t|
    t.integer  "subject_term_id",   :null => false
    t.integer  "predicate_term_id", :null => false
    t.integer  "object_term_id",    :null => false
    t.integer  "ontology_id",       :null => false
    t.integer  "distance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_path", ["subject_term_id", "predicate_term_id", "object_term_id", "ontology_id", "distance"], :name => "term_path_idx", :unique => true

  create_table "term_relationship", :primary_key => "term_relationship_id", :force => true do |t|
    t.integer  "subject_term_id",   :null => false
    t.integer  "predicate_term_id", :null => false
    t.integer  "object_term_id",    :null => false
    t.integer  "ontology_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_relationship", ["subject_term_id", "predicate_term_id", "object_term_id", "ontology_id"], :name => "term_relationship_idx", :unique => true

  create_table "term_relationship_term", :primary_key => "term_id", :force => true do |t|
    t.integer  "term_relationship_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_relationship_term", ["term_id"], :name => "term_relationship_term_idx", :unique => true

  create_table "term_synonym", :id => false, :force => true do |t|
    t.string   "synonym",    :null => false
    t.integer  "term_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "track_configurations", :force => true do |t|
    t.integer  "track_layout_id"
    t.integer  "track_id"
    t.integer  "user_id"
    t.string   "name"
    t.string   "data"
    t.string   "edit"
    t.string   "height"
    t.string   "showControls"
    t.string   "showAdd"
    t.string   "single"
    t.string   "color_above"
    t.string   "color_below"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "track_layouts", :force => true do |t|
    t.integer  "bioentry_id"
    t.integer  "user_id"
    t.string   "name"
    t.string   "assembly"
    t.string   "position"
    t.string   "bases"
    t.string   "pixels"
    t.string   "active_tracks"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tracks", :force => true do |t|
    t.string   "type"
    t.integer  "bioentry_id"
    t.integer  "experiment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sample"
    t.integer  "source_term_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password",   :limit => 128
    t.boolean  "is_ldap",                             :default => false, :null => false
    t.string   "login",                                                  :null => false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  create_table "versions", :force => true do |t|
    t.string   "item_type",   :null => false
    t.string   "item_id",     :null => false
    t.string   "event",       :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "parent_id"
    t.string   "parent_type"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"
  add_index "versions", ["parent_type", "parent_id", "item_type"], :name => "index_versions_on_parent_type_and_parent_id_and_item_type"

end
