class CreateGeneModels < ActiveRecord::Migration
  def self.up
    create_table :gene_models, :force => true do |t|
      t.string :transcript_id
      t.string :protein_id
      t.integer :variants
      t.string :locus_tag
      t.string :gene_name
      t.integer :start_pos
      t.integer :end_pos
      t.integer :strand
      t.integer :rank
      t.references :gene
      t.references :cds
      t.references :mrna
      t.references :bioentry
    end
    add_index(:gene_models, [:gene_id], :name => :gene_models_idx)
    add_index(:gene_models, [:cds_id], :name => :gene_models_idx_1)
    add_index(:gene_models, [:mrna_id], :name => :gene_models_idx_2)
    add_index(:gene_models, :bioentry_id, :name => :gene_models_idx_3)
  end

  def self.down
    drop_table :gene_models
  end
end
