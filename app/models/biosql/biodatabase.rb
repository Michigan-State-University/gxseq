class Biodatabase < ActiveRecord::Base
  set_table_name "biodatabase"
  set_primary_key :biodatabase_id
  has_and_belongs_to_many :taxons
  has_many :bioentries, :class_name =>"Bioentry", :foreign_key => "biodatabase_id"
  # sync up all of the items in the database. Generate denormalized views / tracks / assets
  def sync_database
    # Build GeneModels from gene / cds / mrna pairs based on locus_tag.
    # TODO: replace this with seqfeature relationship?
    begin
      GeneModel.generate
    rescue
      puts $!
    end
    # generate the sequence data for bioentries
    begin    
      bioentries.each do |b|
        b.create_tracks
        b.biosequence.generate_gc_data
      end
    rescue
      puts $!
    end
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

