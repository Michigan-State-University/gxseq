class Location < ActiveRecord::Base
  set_table_name "location"
  #has_paper_trail #must be defined before set_primary_key 
  set_primary_key :location_id
  has_paper_trail :meta => {
    :parent_id => Proc.new { |l| l.seqfeature.id },
    :parent_type => Proc.new { |l| l.seqfeature.class.sti_name }
  }
  belongs_to :seqfeature, :foreign_key => :seqfeature_id
  belongs_to :dbxref, :class_name => "Dbxref"
  belongs_to :term, :class_name => "Term"
  has_many :location_qualifier_values, :class_name => "LocationQualifierValue"
  
  validates_presence_of :start_pos
  validates_presence_of :end_pos
  validate :check_orientation
  after_save :update_related
    
  def to_s
    "#{start_pos}..#{end_pos}"
  end
  
  ## strand cascade method
  ## if this location takes part in a gene_model definition, cascade any changes to strand.
  def update_related
    if(self.seqfeature.respond_to?('gene_models')&&gene_models=self.seqfeature.gene_models)
      gene_models.each do |gm|
        ["cds","mrna","gene"].each do |feature_type|
          if(s=gm.send(feature_type))
            s.locations.each do |l|
              l.update_attribute(:strand, self.strand) if l.strand != self.strand
            end
          end
        end
        gm.update_attribute(:strand, self.strand) if gm.strand != self.strand
      end  
    end
    
  end
  
  protected
  
  def check_orientation
    return true unless self.start_pos && self.end_pos
    if(end_pos <= start_pos)
      self.errors.add(:start_pos, "must be less than end_pos")
      return false
    else
      return true
    end
  end
end



# == Schema Information
#
# Table name: sg_location
#
#  oid        :integer(38)     not null, primary key
#  start_pos  :integer(10)
#  end_pos    :integer(10)
#  strand     :boolean(1)      default(FALSE), not null
#  rank       :integer(4)      not null
#  fea_oid    :integer(38)     not null
#  dbx_oid    :integer(38)
#  trm_oid    :integer(38)
#  deleted_at :datetime
#  updated_at :datetime
#

