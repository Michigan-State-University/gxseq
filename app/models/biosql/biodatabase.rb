class Biodatabase < ActiveRecord::Base
  set_table_name "biodatabase"
  set_primary_key :biodatabase_id
  has_and_belongs_to_many :taxons
  has_many :bioentries, :class_name =>"Bioentry", :foreign_key => "biodatabase_id"
  # sync up all of the items in the database. Generate denormalized data / tracks / assets
  def sync_database
    # Build GeneModels from gene / cds / mrna pairs based on locus_tag.
    # TODO: replace this with seqfeature relationship?
    # TODO: verify genbank, order dependent, gene->mrna->cds pairings / allow manipulation?
    puts "Syncing database"
    begin
      "Syncing Gene Models"
      GeneModel.generate
    rescue
      puts $!
      return false
    end
    # generate the sequence data for bioentries
    begin
      puts "Syncing GC data"
      bioentries.includes(:models_track,:six_frame_track,:generic_feature_track,:gc_file,:taxon_version).find_in_batches(:batch_size => 500) do |entry_batch|
        entry_batch.each do | bioentry |
          bioentry.create_tracks
          #TODO: Fix GC data for transcriptome. Use one file for full TaxonVersion
          if(bioentry.taxon_version.is_genome?)
            bioentry.biosequence.generate_gc_data unless bioentry.gc_file
          end
        end
      end
    rescue
      puts $!
      return false
    end
    # Update the bioentry index
    begin
      puts "Re-indexing sequence"
      progress_bar = ProgressBar.new(Bioentry.count)
      Bioentry.solr_reindex(:batch_size => 50,:progress_bar => progress_bar)
      puts "Re-indexing features"
      progress_bar = ProgressBar.new(Seqfeature.count)
      Seqfeature.solr_reindex(:batch_size => 50,:progress_bar => progress_bar)
    rescue
      puts $!
      return false
    end
    return true
  end
  
end



# == Schema Information
#
# Table name: sg_biodatabase
#
#  oid         :integer(38)     not null, primary key
#  name        :string(32)      not null
#  authority   :string(32)
#  description :string(256)
#  acronym     :string(12)
#  uri         :string(128)
#  deleted_at  :datetime
#  updated_at  :datetime
#

