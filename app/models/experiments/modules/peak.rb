class Peak < ActiveRecord::Base
  belongs_to :experiment
  belongs_to :bioentry
  validates_presence_of :start_pos
  validates_presence_of :end_pos
  validates_presence_of :pos
  validates_presence_of :val
  validates_format_of :val, :with => /^[\d]+$|^[\d]*(\.\d+){0,1}$/, :on => :create, :message => "is invalid"

  named_scope :with_bioentry, lambda { |id|
        { :conditions => { :bioentry_id => id } }
      }
  # TODO: too slow for hundreds of peaks convert to a single statement. Maybe a scope on gene? --with_experiment_peaks
  def nearest_genes
    Gene.joins{
        [locations, qualifiers.term]
      }.where{
        (bioentry_id == my{bioentry_id}) &
        (term.name =='locus_tag') &
        (
          ((locations.start_pos >= my{start_pos}) & (locations.start_pos <= my{self.end_pos}) & (locations.strand == 1)) |
          ((locations.end_pos >= my{start_pos}) & (locations.end_pos <= my{self.end_pos}) & (locations.strand == -1))
        )
      }
  end
end