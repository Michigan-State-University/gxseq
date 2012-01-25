class Asset < ActiveRecord::Base
  require "open3"
  belongs_to :experiment
  validates_presence_of :experiment
  #validate  :check_data_format, :if => %q(self.data.file? && !self.validated), :on => :create
  validate  :check_data_format
  validates_presence_of :type
  validates_inclusion_of :type, :in => %w( Wig BigWig MaqIndel MaqSnp Bam BamIndex), :on => :create, :message => "not available"
  before_validation :initialize_attr
  
  has_attached_file :data, :path => ":rails_root/lib/data/experiments/:exp_class/:exp_id/:id/:filename_with_ext" 
  validates_attachment_presence :data
  has_paper_trail :ignore => [:state]
  has_console_log
  
  attr_accessor :warnings
  attr_accessor :validated
  
  def initialize_attr
    self.warnings = []
    #self.validated = false
  end
  
  def full_filename
    #return the interpolated filename
    name = File.basename(data.path)
  end
  
  def filename
    #return the interpolated filename
    name = File.basename(data.path)
    if(name.length > 20)
      return "#{name[0,12]}..#{name[-7,7]}"
    else
      return name
    end
  end
  
  #parse the file format, return (boolean 'valid', array 'error strings')
  def check_data_format
    #validation performed by sublcasses
  end
 
  #allow assignment to STI type from form
  def attributes_protected_by_default
    super - [self.class.inheritance_column]
  end
  
  # convert class type to STI column (form selected) type #http://coderrr.wordpress.com/2008/04/22/building-the-right-class-with-sti-in-rails/#comment-1826
  # allows the immediate calling of class specific validation/post-processing
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
  
  #Generic Methods - override in sub-classes
  def load_data
  end
  
  def remove_data
  end
  
  def file_details
  end
end