class Asset < ActiveRecord::Base
  require "open3"
  belongs_to :experiment
  validates_presence_of :experiment
  validates_presence_of :type
  validates_inclusion_of :type, :in => %w(Bam Bcf BigWig Vcf Wig Tabix VcfTabix Txt), :on => :create, :message => "not available"
  
  has_attached_file :data, :path => ":rails_root/lib/data/experiments/:exp_class/:exp_id/:id/:filename_with_ext" 
  validates_attachment_presence :data
  has_paper_trail :ignore => [:state]
  has_console_log
  
  def creator
    who_id = versions.last.whodunnit
    who_id ? User.find(versions.last.whodunnit) : nil
  end
    
  #returns the filename
  def filename
    name = File.basename(data.path)
  end
  
  #returns the truncated filename
  def truncated_filename(pre=12,post=7,join="..")
    name = File.basename(data.path)
    if(name.length > pre+post+join.size)
      return "#{name[0,pre]}..#{name[-post,post]}"
    else
      return name
    end
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