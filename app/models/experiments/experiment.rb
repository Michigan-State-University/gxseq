class Experiment < ActiveRecord::Base
  include HasPeaks
  include Smoothable
  belongs_to :user
  belongs_to :taxon_version
  belongs_to :group
  has_many :bioentries_experiments, :dependent => :destroy
  #has_many through is ignoring the set_primary_key definition. Need to fix this!
  #has_many :bioentries, :through => :bioentries_experiments
  has_many :bioentries, :finder_sql => 'select b.* from bioentries_experiments be left outer join bioentry b on be.bioentry_id = b.bioentry_id where be.experiment_id =#{id}'
  has_many :assets, :dependent => :destroy
  has_many :components
  has_many :tracks
  validates_presence_of :user
  # We don't force an assets presence. It might be added later or an expression only rna_seq
  # validates_presence_of :assets
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:taxon_version_id,:type], :message => " has already been used"
  validates_length_of :name, :maximum => 35, :on => :create, :message => "must be less than 35 characters"
  validates_length_of :description, :maximum => 500, :on => :create, :message => "must be less than 500 characters"
  validates_presence_of :taxon_version
  
  accepts_nested_attributes_for :bioentries_experiments, :allow_destroy => true
  accepts_nested_attributes_for :assets, :allow_destroy => true
  
  before_validation :initialize_assets, :on => :create
  before_create 'self.state = "pending"'
  after_save :create_tracks
  after_create :initialize_experiment
  has_paper_trail :ignore => [:state]
  has_console_log
  
  scope :order_by, lambda { |o|
        { :order => o }
      }
  
  
## Class Methods
# TODO: Document to_label remove if unused
  def self.to_label
    name
  end

## Generalized methods (should be specialized in subclass)
  # Defines assets that will be available in the Experiment dropdown.
  # Types must also be whitelisted in - Asset::validates_inclusion_of :type
  # - hash: {key => value} == {DisplayName => ClassName}
  def asset_types
    {'Text' => 'Text'}
  end
  # returns data for the given range and sequence name
  def summary_data(start,stop,num,chrom)
  end
  # Builds new tracks to represent asset data
  # TODO - can this be removed, using the experiment for track info instead? Are there any samples with >1 track per sequence
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
  # update clone method for deep clone of bioentry <-> experiment association
  # Used when cloning experiments for smoothing
  def clone(hsh={})
    e = super()
    self.bioentries_experiments.each do |be|
      e.bioentries_experiments << be.clone
    end
    hsh.each_pair do |k,v|
      if(k.respond_to?('to_s') && e.respond_to?(k.to_s+"="))
        e.send(k.to_s+"=",v)
      end
    end
    return e
  end

  # write out a temporary chrom.sizes file using the sequence list
  def get_chrom_file
    chr = Tempfile.new("chrom.sizes")
    bioentries_experiments.each do |be|
      chr.puts "#{be.sequence_name} #{be.bioentry.length}"
    end 
    chr.flush
    return chr
  end


  # before validating set the reverse association for assets. Otherwise nested validation fails
  # TODO: test new rails 3 reverse association for nested attributes
  def initialize_assets
    assets.each { |a| a.experiment = self }
  end

  # process asset data
  # Run immediately after create
  def initialize_experiment
    puts "Initializing Experiment #{Time.now}"
    update_attribute(:state, "loading")
    self.remove_asset_data
    update_attribute(:state, self.load_asset_data ? "complete" : "error")
    puts "Finished Initialization #{Time.now}"
  end
  handle_asynchronously :initialize_experiment  
  
  # Virtual Method Override - When the tv_id is set re-create the habtm for each sequence in the list.
  def taxon_version_id=(tv_id)    
    if(tv_id.to_i == self.taxon_version_id)
      return super(tv_id)
    end
    tv = TaxonVersion.find(tv_id)
    self.bioentries_experiments.destroy_all
    tv.bioentries.each do |b|
      self.bioentries_experiments.build(:bioentry => b,:sequence_name => b.accession,:experiment => self)
    end
    
    super(tv_id)
  end
  
  ## Convienence Methods
  def taxon_version_name
    taxon_version.name_with_version if taxon_version
  end
  
  def display_name
    self.name
  end
  
  def display_info
    "#{display_name} - #{taxon_version_name}"
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
    bioentries_experiments.find_by_bioentry_id(id).sequence_name
  end
  # return the chrom name for a bioentry ... duplication? TODO Fix duplication
  def get_chrom(bioentry_id)
    be = self.bioentries_experiments.where(:bioentry_id=>bioentry_id).first
    if(be)
      be.sequence_name
    else
      nil
    end
  end
end

# == Schema Information
#
# Table name: experiments
#
#  id          :integer(38)     not null, primary key
#  bioentry_id :integer(38)
#  user_id     :integer(38)
#  name        :string(255)
#  type        :string(255)
#  description :string(255)
#  file_name   :string(255)
#  a_op        :string(255)
#  b_op        :string(255)
#  mid_op      :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  creator_id  :integer(38)
#  updater_id  :integer(38)
#  abs_max     :string(255)
#

