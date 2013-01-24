class SequenceFile < ActiveRecord::Base
  belongs_to :biosequence, :foreign_key => [:bioentry_id,:version]
  #TODO: Refactor sequence_file only 1 per taxon_version
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
  
  #parse the file format, return (boolean 'valid', array 'error strings')
  def check_data_format
    #validation performed by sublcasses
  end
 
  #allow assignment to STI type from form
  def attributes_protected_by_default
    super - [self.class.inheritance_column]
  end
  
  #convert class type to STI form type #http://coderrr.wordpress.com/2008/04/22/building-the-right-class-with-sti-in-rails/#comment-1826
  class << self
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and (klass = type.constantize) != self
        raise "wtF hax!!"  unless klass < self  # klass should be a descendant of us
        return klass.new(*a, &b)
      end
      
      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast
  end
end