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

ActiveRecord::Schema.define(:version => 20130325195644) do

  create_table "assemblies", :force => true do |t|
    t.integer  "taxon_id",   :precision => 38, :scale => 0
    t.integer  "species_id", :precision => 38, :scale => 0
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "group_id",   :precision => 38, :scale => 0
  end

  create_table "assets", :force => true do |t|
    t.string   "type"
    t.integer  "experiment_id",     :precision => 38, :scale => 0
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.string   "state",                                            :default => "pending"
    t.integer  "data_file_size",    :precision => 38, :scale => 0
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
    t.integer "biodatabase_id", :precision => 38, :scale => 0
    t.integer "taxon_id",       :precision => 38, :scale => 0
  end

  create_table "bioentry", :primary_key => "bioentry_id", :force => true do |t|
    t.integer  "assembly_id",    :limit => 10,   :precision => 10, :scale => 0, :null => false
    t.integer  "biodatabase_id", :limit => 10,   :precision => 10, :scale => 0, :null => false
    t.integer  "taxon_id",       :limit => 10,   :precision => 10, :scale => 0
    t.string   "name",           :limit => 40,                                  :null => false
    t.string   "accession",      :limit => 128,                                 :null => false
    t.string   "identifier",     :limit => 40
    t.string   "division",       :limit => 6
    t.string   "description",    :limit => 4000
    t.string   "version",                                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry", ["version"], :name => "bioentry_idx_2"

  create_table "bioentry_dbxref", :id => false, :force => true do |t|
    t.integer  "bioentry_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "dbxref_id",   :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "rank",                      :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bioentry_path", :id => false, :force => true do |t|
    t.integer  "object_bioentry_id",  :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "subject_bioentry_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "term_id",             :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "distance",            :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry_path", ["object_bioentry_id", "subject_bioentry_id", "term_id", "distance"], :name => "bioentry_path_idx", :unique => true

  create_table "bioentry_qualifier_value", :id => false, :force => true do |t|
    t.integer  "bioentry_id", :limit => 10,   :precision => 10, :scale => 0,                :null => false
    t.integer  "term_id",     :limit => 10,   :precision => 10, :scale => 0,                :null => false
    t.string   "value",       :limit => 4000
    t.integer  "rank",        :limit => 5,    :precision => 5,  :scale => 0, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry_qualifier_value", ["bioentry_id", "term_id", "rank"], :name => "bioentry_qualifier_value_idx", :unique => true

  create_table "bioentry_reference", :id => false, :force => true do |t|
    t.integer  "bioentry_id",  :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.integer  "reference_id", :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.integer  "start_pos",    :limit => 10, :precision => 10, :scale => 0
    t.integer  "end_pos",      :limit => 10, :precision => 10, :scale => 0
    t.integer  "rank",                       :precision => 38, :scale => 0, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bioentry_relationship", :primary_key => "bioentry_relationship_id", :force => true do |t|
    t.integer  "object_bioentry_id",  :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "subject_bioentry_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "term_id",             :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "rank",                :limit => 5,  :precision => 5,  :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bioentry_relationship", ["object_bioentry_id", "subject_bioentry_id", "term_id"], :name => "bioentry_relationship_idx", :unique => true

  create_table "biosequence", :id => false, :force => true do |t|
    t.integer  "bioentry_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "version",                   :precision => 38, :scale => 0
    t.integer  "length",      :limit => 10, :precision => 10, :scale => 0
    t.string   "alphabet",    :limit => 10
    t.text     "seq"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blast_databases", :force => true do |t|
    t.string   "name"
    t.string   "link_ref"
    t.string   "description"
    t.string   "taxon_id"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size",    :precision => 38, :scale => 0
    t.datetime "data_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filepath"
    t.integer  "group_id",          :precision => 38, :scale => 0
  end

  create_table "blast_reports", :force => true do |t|
    t.integer  "seqfeature_id",                 :precision => 38, :scale => 0
    t.integer  "blast_run_id",                  :precision => 38, :scale => 0
    t.text     "report"
    t.string   "hit_acc"
    t.string   "hit_def",       :limit => 4000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blast_runs", :force => true do |t|
    t.integer "blast_database_id",                :precision => 38, :scale => 0
    t.integer "assembly_id",                      :precision => 38, :scale => 0
    t.text    "parameters"
    t.string  "program"
    t.string  "version"
    t.string  "reference",         :limit => 500
    t.string  "db"
    t.integer "user_id",                          :precision => 38, :scale => 0
  end

  create_table "comments", :primary_key => "comments_id", :force => true do |t|
    t.integer  "bioentry_id",  :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.text     "comment_text",                                                             :null => false
    t.integer  "rank",                       :precision => 38, :scale => 0, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["bioentry_id", "rank"], :name => "comments_idx", :unique => true

  create_table "components", :force => true do |t|
    t.string   "type"
    t.integer  "experiment_id",           :precision => 38, :scale => 0
    t.integer  "synthetic_experiment_id", :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "concordance_items", :force => true do |t|
    t.integer  "concordance_set_id", :precision => 38, :scale => 0
    t.integer  "bioentry_id",        :precision => 38, :scale => 0
    t.string   "reference_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "concordance_sets", :force => true do |t|
    t.integer  "assembly_id", :precision => 38, :scale => 0
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "console_logs", :force => true do |t|
    t.integer  "loggable_id",   :precision => 38, :scale => 0
    t.string   "loggable_type"
    t.text     "console"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dbxref", :primary_key => "dbxref_id", :force => true do |t|
    t.string   "dbname",     :limit => 40,                                 :null => false
    t.string   "accession",  :limit => 128,                                :null => false
    t.integer  "version",                   :precision => 38, :scale => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dbxref", ["accession", "dbname", "version"], :name => "dbxref_idx", :unique => true

  create_table "dbxref_qualifier_value", :id => false, :force => true do |t|
    t.integer  "dbxref_id",  :limit => 10,   :precision => 10, :scale => 0,                :null => false
    t.integer  "term_id",    :limit => 10,   :precision => 10, :scale => 0,                :null => false
    t.integer  "rank",                       :precision => 38, :scale => 0, :default => 0, :null => false
    t.string   "value",      :limit => 4000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",     :precision => 38, :scale => 0, :default => 0
    t.integer  "attempts",     :precision => 38, :scale => 0, :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
    t.integer  "user_id",      :precision => 38, :scale => 0
    t.datetime "completed_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "experiments", :force => true do |t|
    t.integer  "assembly_id",                        :precision => 38, :scale => 0
    t.integer  "user_id",                            :precision => 38, :scale => 0
    t.string   "name"
    t.string   "type"
    t.string   "description",        :limit => 2000
    t.string   "file_name"
    t.string   "a_op"
    t.string   "b_op"
    t.string   "mid_op"
    t.string   "sequence_name"
    t.string   "state"
    t.string   "show_negative"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id",                           :precision => 38, :scale => 0
    t.integer  "concordance_set_id",                 :precision => 38, :scale => 0
  end

  add_index "experiments", ["assembly_id", "group_id", "user_id"], :name => "experiment_idx1"

  create_table "favorites", :force => true do |t|
    t.integer  "user_id",          :precision => 38, :scale => 0
    t.string   "type"
    t.integer  "favorite_item_id", :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feature_counts", :force => true do |t|
    t.integer  "seqfeature_id",    :precision => 38, :scale => 0
    t.integer  "experiment_id",    :precision => 38, :scale => 0
    t.integer  "count",            :precision => 38, :scale => 0
    t.decimal  "normalized_count", :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feature_counts", ["experiment_id", "seqfeature_id"], :name => "idx$$_31e30001"
  add_index "feature_counts", ["seqfeature_id"], :name => "idx$$_31e60001"

  create_table "gene_models", :force => true do |t|
    t.string  "transcript_id"
    t.string  "protein_id"
    t.integer "variants",      :precision => 38, :scale => 0
    t.string  "locus_tag"
    t.string  "gene_name"
    t.integer "start_pos",     :precision => 38, :scale => 0
    t.integer "end_pos",       :precision => 38, :scale => 0
    t.integer "strand",        :precision => 38, :scale => 0
    t.integer "rank",          :precision => 38, :scale => 0
    t.integer "gene_id",       :precision => 38, :scale => 0
    t.integer "cds_id",        :precision => 38, :scale => 0
    t.integer "mrna_id",       :precision => 38, :scale => 0
    t.integer "bioentry_id",   :precision => 38, :scale => 0
  end

  add_index "gene_models", ["bioentry_id"], :name => "gene_models_idx_3"
  add_index "gene_models", ["cds_id"], :name => "gene_models_idx_1"
  add_index "gene_models", ["gene_id"], :name => "gene_models_idx"
  add_index "gene_models", ["mrna_id"], :name => "gene_models_idx_2"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "owner_id",   :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id", :precision => 38, :scale => 0
    t.integer "user_id",  :precision => 38, :scale => 0
  end

  add_index "groups_users", ["group_id", "user_id"], :name => "groups_users_idx1"

  create_table "location", :primary_key => "location_id", :force => true do |t|
    t.integer  "seqfeature_id", :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.integer  "dbxref_id",     :limit => 10, :precision => 10, :scale => 0
    t.integer  "term_id",       :limit => 10, :precision => 10, :scale => 0
    t.integer  "start_pos",     :limit => 10, :precision => 10, :scale => 0
    t.integer  "end_pos",       :limit => 10, :precision => 10, :scale => 0
    t.integer  "strand",                      :precision => 38, :scale => 0, :default => 0, :null => false
    t.integer  "rank",                        :precision => 38, :scale => 0, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "location", ["seqfeature_id", "rank"], :name => "location_idx", :unique => true
  add_index "location", ["seqfeature_id"], :name => "location_idx_1"
  add_index "location", ["term_id"], :name => "idx$$_32830001"

  create_table "location_qualifier_value", :id => false, :force => true do |t|
    t.integer  "location_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "term_id",     :limit => 10, :precision => 10, :scale => 0, :null => false
    t.string   "value",                                                    :null => false
    t.integer  "int_value",   :limit => 10, :precision => 10, :scale => 0
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
    t.integer  "experiment_id", :precision => 38, :scale => 0
    t.integer  "bioentry_id",   :precision => 38, :scale => 0
    t.integer  "start_pos",     :precision => 38, :scale => 0
    t.integer  "end_pos",       :precision => 38, :scale => 0
    t.decimal  "val"
    t.integer  "pos",           :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.string   "name",                                      :null => false
    t.integer  "owner_id",   :precision => 38, :scale => 0, :null => false
    t.string   "owner_type",                                :null => false
    t.integer  "group_id",   :precision => 38, :scale => 0
    t.string   "group_type"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["owner_id", "owner_type", "name", "group_id", "group_type"], :name => "owner_name_group_pref_idx", :unique => true

  create_table "reference", :primary_key => "reference_id", :force => true do |t|
    t.integer  "dbxref_id",  :limit => 10,   :precision => 10, :scale => 0
    t.string   "location",   :limit => 4000,                                :null => false
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
    t.integer "role_id", :precision => 38, :scale => 0
    t.integer "user_id", :precision => 38, :scale => 0
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "seqfeature", :primary_key => "seqfeature_id", :force => true do |t|
    t.integer  "bioentry_id",    :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.integer  "type_term_id",   :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.integer  "source_term_id", :limit => 10, :precision => 10, :scale => 0,                :null => false
    t.string   "display_name",   :limit => 64
    t.integer  "rank",                         :precision => 38, :scale => 0, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature", ["bioentry_id", "type_term_id", "source_term_id", "rank"], :name => "seqfeature_idx", :unique => true
  add_index "seqfeature", ["display_name"], :name => "seqfeature_idx_1"
  add_index "seqfeature", ["type_term_id", "seqfeature_id"], :name => "idx$$_31e30002"

  create_table "seqfeature_dbxref", :id => false, :force => true do |t|
    t.integer  "seqfeature_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "dbxref_id",     :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "rank",                        :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "seqfeature_path", :id => false, :force => true do |t|
    t.integer  "object_seqfeature_id",  :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "subject_seqfeature_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "term_id",               :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "distance",              :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature_path", ["object_seqfeature_id", "subject_seqfeature_id", "term_id", "distance"], :name => "seqfeature_path_idx", :unique => true

  create_table "seqfeature_qualifier_value", :id => false, :force => true do |t|
    t.integer  "seqfeature_id", :limit => 10,   :precision => 10, :scale => 0,                :null => false
    t.integer  "term_id",       :limit => 10,   :precision => 10, :scale => 0,                :null => false
    t.integer  "rank",                          :precision => 38, :scale => 0, :default => 0, :null => false
    t.string   "value",         :limit => 4000,                                               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature_qualifier_value", ["seqfeature_id", "term_id", "rank"], :name => "sqv_idx_2", :unique => true
  add_index "seqfeature_qualifier_value", ["seqfeature_id"], :name => "sqv_idx"
  add_index "seqfeature_qualifier_value", ["term_id"], :name => "sqv_idx_1"
  add_index "seqfeature_qualifier_value", ["value"], :name => "sqv_idx_3"

  create_table "seqfeature_relationship", :primary_key => "seqfeature_relationship_id", :force => true do |t|
    t.integer  "object_seqfeature_id",  :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "subject_seqfeature_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "term_id",               :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "rank",                  :limit => 5,  :precision => 5,  :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seqfeature_relationship", ["object_seqfeature_id", "subject_seqfeature_id", "term_id"], :name => "seqfeature_relationship_idx", :unique => true

  create_table "sequence_files", :force => true do |t|
    t.string   "type"
    t.integer  "assembly_id",       :precision => 38, :scale => 0
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size",    :precision => 38, :scale => 0
    t.datetime "data_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sequence_files", ["assembly_id"], :name => "i_sequence_files_assembly_id"

  create_table "sequence_variants", :force => true do |t|
    t.integer  "experiment_id", :precision => 38, :scale => 0
    t.integer  "bioentry_id",   :precision => 38, :scale => 0
    t.integer  "pos",           :precision => 38, :scale => 0
    t.string   "ref"
    t.string   "alt"
    t.integer  "qual",          :precision => 38, :scale => 0
    t.decimal  "frequency"
    t.string   "type"
    t.integer  "depth",         :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sequence_variants", ["bioentry_id", "pos"], :name => "seq_variant_idx_4"
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
    t.integer  "ncbi_taxon_id",     :limit => 10, :precision => 10, :scale => 0
    t.integer  "parent_taxon_id",   :limit => 10, :precision => 10, :scale => 0
    t.string   "node_rank",         :limit => 32
    t.integer  "genetic_code",                    :precision => 38, :scale => 0
    t.integer  "mito_genetic_code",               :precision => 38, :scale => 0
    t.integer  "left_value",        :limit => 10, :precision => 10, :scale => 0
    t.integer  "right_value",       :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "non_ncbi",                        :precision => 38, :scale => 0, :default => 0
  end

  add_index "taxon", ["left_value"], :name => "taxon_idx_1", :unique => true
  add_index "taxon", ["ncbi_taxon_id"], :name => "taxon_idx", :unique => true
  add_index "taxon", ["right_value"], :name => "taxon_idx_2", :unique => true

  create_table "taxon_name", :id => false, :force => true do |t|
    t.integer  "taxon_id",   :limit => 10, :precision => 10, :scale => 0, :null => false
    t.string   "name",                                                    :null => false
    t.string   "name_class", :limit => 32,                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taxon_name", ["name"], :name => "taxon_name_idx2"
  add_index "taxon_name", ["taxon_id", "name", "name_class"], :name => "taxon_name_idx", :unique => true

  create_table "term", :primary_key => "term_id", :force => true do |t|
    t.string   "name",                                                       :null => false
    t.string   "definition",  :limit => 4000
    t.string   "identifier",  :limit => 40
    t.string   "is_obsolete", :limit => 1
    t.integer  "ontology_id", :limit => 10,   :precision => 10, :scale => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term", ["name", "ontology_id", "is_obsolete"], :name => "term_idx_1", :unique => true
  add_index "term", ["name"], :name => "term_idx_2"

  create_table "term_dbxref", :id => false, :force => true do |t|
    t.integer  "term_id",    :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "dbxref_id",  :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "rank",                     :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "term_path", :primary_key => "term_path_id", :force => true do |t|
    t.integer  "subject_term_id",   :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "predicate_term_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "object_term_id",    :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "ontology_id",       :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "distance",          :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_path", ["subject_term_id", "predicate_term_id", "object_term_id", "ontology_id", "distance"], :name => "term_path_idx", :unique => true

  create_table "term_relationship", :primary_key => "term_relationship_id", :force => true do |t|
    t.integer  "subject_term_id",   :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "predicate_term_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "object_term_id",    :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "ontology_id",       :limit => 10, :precision => 10, :scale => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_relationship", ["subject_term_id", "predicate_term_id", "object_term_id", "ontology_id"], :name => "term_relationship_idx", :unique => true

  create_table "term_relationship_term", :id => false, :force => true do |t|
    t.integer  "term_relationship_id", :limit => 10, :precision => 10, :scale => 0, :null => false
    t.integer  "term_id",              :limit => 10, :precision => 10, :scale => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_relationship_term", ["term_id"], :name => "term_relationship_term_idx", :unique => true

  create_table "term_synonym", :id => false, :force => true do |t|
    t.string   "ora_synonym",                                              :null => false
    t.integer  "term_id",     :limit => 10, :precision => 10, :scale => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "track_configurations", :force => true do |t|
    t.integer  "track_layout_id", :precision => 38, :scale => 0
    t.integer  "track_id",        :precision => 38, :scale => 0
    t.integer  "user_id",         :precision => 38, :scale => 0
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
    t.integer  "assembly_id",   :precision => 38, :scale => 0
    t.integer  "user_id",       :precision => 38, :scale => 0
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
    t.integer  "assembly_id",    :precision => 38, :scale => 0
    t.integer  "experiment_id",  :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sample"
    t.integer  "source_term_id", :precision => 38, :scale => 0
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password",   :limit => 128
    t.boolean  "is_ldap",                             :precision => 1,  :scale => 0, :default => false, :null => false
    t.string   "login",                                                                                 :null => false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :precision => 38, :scale => 0, :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                     :precision => 38, :scale => 0, :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], :name => "i_users_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  create_table "versions", :force => true do |t|
    t.string   "item_type",                                  :null => false
    t.string   "item_id",                                    :null => false
    t.string   "event",                                      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "parent_id",   :precision => 38, :scale => 0
    t.string   "parent_type"
  end

  add_index "versions", ["item_type", "item_id"], :name => "i_versions_item_type_item_id"
  add_index "versions", ["parent_type", "parent_id", "item_type"], :name => "i_ver_par_typ_par_id_ite_typ"

end
