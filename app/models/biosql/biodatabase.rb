# == Schema Information
#
# Table name: biodatabase
#
#  authority      :string(128)
#  biodatabase_id :integer          not null, primary key
#  created_at     :datetime
#  description    :string(4000)
#  name           :string(128)      not null
#  updated_at     :datetime
#

class Biosql::Biodatabase < ActiveRecord::Base
  set_table_name "biodatabase"
  set_primary_key :biodatabase_id
  has_and_belongs_to_many :taxons
  has_many :bioentries, :class_name =>"Bioentry", :foreign_key => "biodatabase_id"
  # sync up all of the items in the database. Generate denormalized data / tracks / assets
  def sync_database
    # Build GeneModels from gene / cds / mrna pairs based on locus_tag.
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
      puts "Syncing Assembly data"
      Assembly.all.each do |assembly|
        assembly.generate_gc_data
        assembly.create_tracks
      end
    rescue
      puts $!
      return false
    end
    # Update the indexes
    begin
      puts "Re-indexing sequence"
      progress_bar = ProgressBar.new(Bioentry.count)
      Bioentry.solr_reindex(:batch_size => 50,:progress_bar => progress_bar)
      puts "Re-indexing features"
      progress_bar = ProgressBar.new(Seqfeature.count)
      Biosql::Feature::Seqfeature.solr_reindex(:batch_size => 50,:progress_bar => progress_bar)
      puts "Re-indexing gene_models"
      progress_bar = ProgressBar.new(GeneModel.count)
      GeneModel.solr_reindex(:batch_size => 50,:progress_bar => progress_bar)
    rescue
      puts $!
      return false
    end
    return true
  end
  
end


