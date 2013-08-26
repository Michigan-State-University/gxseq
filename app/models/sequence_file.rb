# == Schema Information
#
# Table name: sequence_files
#
#  assembly_id       :integer
#  created_at        :datetime
#  data_content_type :string(255)
#  data_file_name    :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#  id                :integer          not null, primary key
#  type              :string(255)
#  updated_at        :datetime
#

class SequenceFile < ActiveRecord::Base
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
