# == Schema Information
#
# Table name: location
#
#  created_at    :datetime
#  dbxref_id     :integer
#  end_pos       :integer
#  location_id   :integer          not null, primary key
#  rank          :integer          default(0), not null
#  seqfeature_id :integer          not null
#  start_pos     :integer
#  strand        :integer          default(0), not null
#  term_id       :integer
#  updated_at    :datetime
#

class Biosql::Location < ActiveRecord::Base
  set_table_name "location"
  set_primary_key :location_id
  has_paper_trail :meta => {
    :parent_id => Proc.new { |l| (l.seqfeature.respond_to?(:gene_model) && l.seqfeature.gene_model) ? l.seqfeature.gene_model.gene_id : l.seqfeature.id},
    :parent_type => Proc.new { |l| (l.seqfeature.respond_to?(:gene_model) && l.seqfeature.gene_model) ? 'Gene' : l.seqfeature.class.name}
  }
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature"
  belongs_to :dbxref, :class_name => "Dbxref"
  belongs_to :term, :class_name => "Term"
  has_many :location_qualifier_values, :class_name => "LocationQualifierValue"

  validates_presence_of :start_pos
  validates_presence_of :end_pos
  validate :check_orientation
  after_save :update_related
  before_save :check_term
  before_validation :update_rank
  
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

  def name
    "#{term.name if term} Location"
  end

  def display_data
    " #{to_s} #{strand == 1 ? '->' : '<-'}"
  end

  protected

  def check_term
    unless term
      self.term_id = seqfeature.type_term_id
    end
  end

  def check_orientation
    return true unless self.start_pos && self.end_pos
    if(end_pos <= start_pos)
      self.errors.add(:start_pos, "must be less than end_pos")
      return false
    else
      return true
    end
  end
  
  # set rank before validation
  def update_rank
    if (!self.rank || self.rank==0) && self.seqfeature
      self.rank = (self.seqfeature.locations.map(&:rank).compact.max||0) + 1
    end
  end
end


