class CreateBlastTables < ActiveRecord::Migration
  def self.up
    create_table :blast_iterations, :force => true do |t|
      t.references :blast_run
      t.references :seqfeature
      t.string :query_id
      t.string :query_def, :limit => 4000
      t.integer :query_len
    end
    
    create_table :hits, :force => true do |t|
      t.references :blast_iteration
      t.string :blast_hit_id, :accession
      t.string :definition, :limit => 4000
      t.integer :length, :hit_num
    end
    
    create_table :hsps, :force => true do |t|
      t.references :hit
      t.float :bit_score
      t.integer :score, :query_from, :query_to, :hit_from, :hit_to, :query_frame, :hit_frame, :identity, :positive, :gaps, :align_length
      t.decimal :evalue
      t.text :query_seq, :hit_seq, :midline
    end
  end

  def self.down
    drop_table :hsps
    drop_table :hits
    drop_table :blast_iterations
  end
end