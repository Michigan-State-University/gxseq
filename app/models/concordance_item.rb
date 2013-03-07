class ConcordanceItem < ActiveRecord::Base
  belongs_to :concordance_set
  belongs_to :bioentry
  validates_presence_of :reference_name
  validates_presence_of :bioentry
  
  scope :with_bioentry, lambda { |id|
        { :conditions => { :bioentry_id => id } }
      }
  def bioentry_short_name
    bioentry.short_name
  end
  
  def bioentry_display_name
    bioentry.display_name
  end
  
  def name
    'Experiment Sequence'
  end
end