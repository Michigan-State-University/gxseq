class SequenceFile < ActiveRecord::Base
  #TODO: Convert Asset,SequenceFile to polymorphic class
  belongs_to :assembly
  has_attached_file :data, :path => ":rails_root/lib/data/sequence/gc/:filename"
  validates_attachment_presence :data
  
  attr_accessor :warnings
  attr_accessor :validated
  
  def initialize(*a, &b)
    self.warnings = []
    self.validated = false
    super
  end
  
  def filename
    #return the interpolated filename
    File.basename(data.path)
  end
end