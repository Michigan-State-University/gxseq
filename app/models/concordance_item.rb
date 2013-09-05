# == Schema Information
#
# Table name: concordance_items
#
#  bioentry_id        :integer
#  concordance_set_id :integer
#  created_at         :datetime
#  id                 :integer          not null, primary key
#  reference_name     :string(255)
#  updated_at         :datetime
#

class ConcordanceItem < ActiveRecord::Base
  belongs_to :concordance_set
  belongs_to :bioentry, :class_name => "Biosql::Bioentry"
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
    'Sample Sequence'
  end
end
