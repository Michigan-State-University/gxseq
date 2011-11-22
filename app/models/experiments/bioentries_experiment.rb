class BioentriesExperiment < ActiveRecord::Base
  belongs_to :bioentry
  belongs_to :experiment
  belongs_to :chip_seq, :class_name => "ChipSeq", :foreign_key => "experiment_id"
  belongs_to :chip_chip, :class_name => "ChipChip", :foreign_key => "experiment_id"
  belongs_to :synthetic, :class_name => "Synthetic", :foreign_key => "experiment_id"
  belongs_to :variant, :class_name => "Variant", :foreign_key => "experiment_id"
  validates_presence_of :bioentry
  validates_presence_of :experiment
  validates_presence_of :sequence_name
  scope :with_bioentry, lambda { |id|
        { :conditions => { :bioentry_id => id } }
      }
  def bioentry_short_name
    bioentry.short_name
  end
  
  def name
    'Experiment Sequence'
  end
end