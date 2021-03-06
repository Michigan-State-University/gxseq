# == Schema Information
#
# Table name: samples
#
#  a_op               :string(255)
#  assembly_id        :integer
#  b_op               :string(255)
#  concordance_set_id :integer
#  created_at         :datetime
#  description        :string(2000)
#  file_name          :string(255)
#  group_id           :integer
#  id                 :integer          not null, primary key
#  mid_op             :string(255)
#  name               :string(255)
#  sequence_name      :string(255)
#  show_negative      :string(255)
#  state              :string(255)
#  total_count        :integer
#  type               :string(255)
#  updated_at         :datetime
#  user_id            :integer
#

class Sample < ActiveRecord::Base
  include HasPeaks
  include Smoothable
  belongs_to :user
  belongs_to :assembly
  belongs_to :group
  belongs_to :concordance_set
  delegate :bioentries, :to => :assembly
  has_many :assets, :dependent => :destroy
  has_many :components
  has_many :tracks
  has_many :traits
  has_many :trait_types, :through => :traits, :source => :term, :uniq => true

  validates_presence_of :user
  validates_presence_of :assembly
  validates_presence_of :concordance_set, :if => "type!='Combo'"
  validates_presence_of :name
  validates_presence_of :type, :message => "not available"
  validates_uniqueness_of :name, :scope => [:type,:assembly_id], :message => " has already been used"
  validates_length_of :name, :maximum => 35, :on => :create, :message => "must be less than 35 characters"
  validates_length_of :description, :maximum => 500, :on => :create, :message => "must be less than 500 characters"
  
  accepts_nested_attributes_for :assets, :allow_destroy => true
  accepts_nested_attributes_for :traits, :allow_destroy => true
  
  before_validation :initialize_assets, :on => :create
  before_create 'self.state = "pending"'
  before_save :update_cache
  after_create :initialize_sample
  after_save :create_tracks
  
  has_paper_trail :ignore => [:state]
  has_console_log
  
## Class Methods
  # returns label used by formtastic in views
  def self.to_label
    name
  end

## Generalized methods (should be specialized in subclass)
  # Defines assets that will be available in the Sample dropdown.
  # Types must also be whitelisted in - Asset::new_with_cast
  # - hash: {key => value} == {DisplayName => ClassName}
  def asset_types
    {'Text' => 'Txt'}
  end
  # returns data for the given range and sequence name
  def summary_data(start,stop,num,bioentry)
  end
  # Builds new tracks to represent asset data
  # TODO - update variants track so we can have 1 per sample and remove tracks entirely. Exp and Assembly instead of tracks
  def create_tracks
  end
  # Processes assets generating any necessary data
  def load_asset_data
    puts "Loading asset data #{Time.now}"
    begin
      assets.each(&:load)
      return true
    rescue
      puts "** Error loading assets:\n#{$!}"
      return false
    end
  end
  # Reverts any processing from load_asset_data
  def remove_asset_data
    puts "Removing all asset data #{Time.now}"
    begin
      assets.each(&:unload)
    rescue
      puts "** Error removing asset data:\n#{$!}"
    end
  end
  
## Instance Methods

  # allow assignment to STI type from form
  def attributes_protected_by_default
    super - [self.class.inheritance_column]
  end

  # convert class type to STI column (form selected) type #http://coderrr.wordpress.com/2008/04/22/building-the-right-class-with-sti-in-rails/#comment-1826
  # allows the immediate calling of class specific validation/post-processing
  class << self
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and ['ChipChip', 'ChipSeq', 'ReSeq', 'RnaSeq', 'Variant'].include?(type)
        klass = type.constantize
        return klass.new_without_cast(*a, &b)
      end
      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast
  end
  
  # Association for concordance_items. nested association had odd behavior with concordance_set_id
  def concordance_items
    ConcordanceItem.where(:concordance_set_id => self.concordance_set_id)
  end
  # update clone method for deep clone of supplied attributes
  def clone(hsh={})
    e = super()
    hsh.each_pair do |k,v|
      if(k.respond_to?('to_s') && e.respond_to?(k.to_s+"="))
        e.send(k.to_s+"=",v)
      end
    end
    return e
  end

  # write out a temporary chrom.sizes file using the concordance_set
  def get_chrom_file
    chr = Tempfile.new("chrom.sizes")
    concordance_items.each do |c_item|
      chr.puts "#{c_item.reference_name} #{c_item.bioentry.length}"
    end 
    chr.flush
    return chr
  end

  # calculates and returns a MAD score
  def median_absolute_deviation(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    # Get Median
    median = DescriptiveStatistics::Stats.new(data).median
    # Get absolute deviation
    abs_dev = data.map{|d| (d-median).abs}
    # get the absolute deviation median
    abs_dev_median = DescriptiveStatistics::Stats.new(abs_dev).median
    # multiply by constant factor == .75 quantile of assumed distribution
    # .75 quantile of normal distribution == 1.4826
    1.4826 * abs_dev_median
  end
  
  # returns the median
  def median(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    median = DescriptiveStatistics::Stats.new(data).median
  end
  
  # returns the stddev
  def stddev(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    DescriptiveStatistics::Stats.new(data).standard_deviation
  end
  
  # returns the mean
  def mean(bioentry,count=2000)
    length = bioentry.length
    data = summary_data(1,length,[count,length].min,bioentry)
    DescriptiveStatistics::Stats.new(data).mean
  end
  
  # before validating set the reverse association for assets. Otherwise nested validation fails
  # TODO: test new rails 3 reverse association for nested attributes
  def initialize_assets
    assets.each { |a| a.sample = self }
  end

  # process asset data
  # Run immediately after create
  def initialize_sample
    puts "Initializing Sample #{Time.now}"
    update_attribute(:state, "loading")
    self.remove_asset_data
    update_attribute(:state, self.load_asset_data ? "complete" : "error")
    puts "Finished Initialization #{Time.now}"
  end
  handle_asynchronously :initialize_sample  
  
  # check if our group has changed and clear user cache if it has
  def update_cache
    Ability.reset_cache if self.group_id_changed?
  end
  
  ## Convienence Methods
  def assembly_name
    assembly.name_with_version if assembly
  end
  
  def display_name
    self.name
  end
  
  def display_info
    "#{display_name} - #{assembly_name}"
  end
  
  def typed_display_name
    "#{self.class.name}: #{display_name}"
  end
  
  def typed_display_info
    "#{self.class.name}: #{display_info}"
  end
  
  # return the sequence name for a bioentry or bioentry_id
  def sequence_name(bioentry)
    if bioentry.respond_to?(:id)
      id = bioentry.id
    else
      id = bioentry.to_i
    end
    concordance_items.find_by_bioentry_id(id).try(:reference_name)
  end
  
  def density_chart_summary(opts={})
    bioentry = opts[:bioentry]
    return [] unless bioentry
    count = opts[:density]||1000
    gap = bioentry.length/count.to_f
    data = [{
      :id  => bioentry.id,
      :name => bioentry.accession,
      :values => summary_data(0,bioentry.length,count,bioentry).collect.with_index{|d,i|
        { :x => (i*gap).to_i, :y => d.round(4) }
      }
    }]
  end
end
