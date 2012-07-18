class Experiment < ActiveRecord::Base
  include Exp::HasPeaks
  include Exp::Smoothable
  belongs_to :user
  belongs_to :taxon_version
  has_many :bioentries_experiments, :dependent => :destroy
  #has_many through is ignoring the set_primary_key definition. Need to fix this!
  #has_many :bioentries, :through => :bioentries_experiments
  has_many :bioentries, :finder_sql => 'select b.* from bioentries_experiments be left outer join bioentry b on be.bioentry_id = b.bioentry_id where be.experiment_id =#{id}'
  has_many :assets, :dependent => :destroy
  has_many :components
  has_many :tracks
  validates_presence_of :user
  #validates_presence_of :assets
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:taxon_version_id,:type], :message => " has already been used"
  validates_length_of :name, :maximum => 35, :on => :create, :message => "must be less than 35 characters"
  validates_length_of :description, :maximum => 500, :on => :create, :message => "must be less than 500 characters"
  validates_presence_of :taxon_version
  
  accepts_nested_attributes_for :bioentries_experiments, :allow_destroy => true
  accepts_nested_attributes_for :assets, :allow_destroy => true
  
  before_validation :initialize_assets, :on => :create
  before_validation :initialize_bioentries, :on => :create
  before_create 'self.state = "pending"'
  after_save :create_tracks
  after_create :initialize_experiment
  has_paper_trail :ignore => [:state]
  has_console_log
  
  scope :order_by, lambda { |o|
        { :order => o }
      }
  
  
## Class Methods
  def self.to_label
    name
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
  
  # Set the experiment state based on the current asset state
  # TODO Refactor .. remove or convert to state machine
  def update_state_from_assets
    self.reload
    states = assets.collect(&:state).uniq
    if states==["pending"]
      self.update_attribute(:state, 'pending')
    elsif states.include?('error')
      puts "!!Changing state to error. Something went wrong parsing assets... #{Time.now}" unless self.state == 'error'
      self.update_attribute(:state, 'error')
    elsif states.include?('loading') || states.include?('pending')
      puts "Changing State To loading #{Time.now}" unless self.state == 'loading'
      self.update_attribute(:state, 'loading')
    else
      puts "Changing State To complete #{Time.now}" unless self.state == 'complete'
      self.update_attribute(:state, 'complete')
    end
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
  
  # convert wig to big_wig and save as a new asset
  def create_big_wig_from_wig
    begin
      raise StandardError, "No wig found!" unless self.wig
      f = wig.data.path+"_bw"
      FileManager.wig_to_bigwig!(wig.data.path, f, get_chrom_file.path)
      self.big_wig = bw = assets.new(:type => "BigWig", :data => File.open(f))
      bw.save!
      FileUtils.rm(f)
    rescue
      logger.error("#{Time.now} \n #{$!}")
      puts "Error: could not convert wig to BigWig #{Time.now}"
    end
  end
    
## Initialization / Callback Methods

  # before validating set the reverse association for assets. Otherwise nested validation fails
  # TODO test new rails 3 reverse association for nested attributes
  def initialize_assets
    assets.each { |a| a.experiment = self }
  end
  
  # TODO needs doc!
  def initialize_bioentries
  end
  
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
  # process asset data
  # Run immediately after create
  def initialize_experiment
    puts "Initializing Experiment #{Time.now}"
    self.remove_asset_data
    self.load_asset_data
    puts "Finished Initialization #{Time.now}"
  end
  handle_asynchronously :initialize_experiment  
  
  
## Convienence Methods

  def display_name
    self.name
  end

  def display_info
    "#{display_name} - [#{bioentries.collect(&:species_name).join(",")}]"
  end

  def detailed_display_info
    "#{self.class.name}: #{display_name} - [#{bioentries.collect(&:species_name).join(",")}]"
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
  
##Generalized methods (should be specialized in subclass)
  # returns data for the given range and sequence name
  def summary_data(start,stop,num,chrom)
  end
  # Builds new tracks to represent asset data
  # TODO - can this be removed?
  def create_tracks
  end
  # Enables parsing / processing asset data on load
  def load_asset_data
    puts "Loading Asset Data - #{Time.now}"
    assets.each{|a| a.load_data}
  end
  # Reverts any processing that occurs on load
  def remove_asset_data
    puts "Removing Asset Data - #{Time.now}"
    assets.each{|a| a.remove_data}
  end
  # Defines assets that will be available in the Experiment dropdown.
  # Types must also be whitelisted in - Asset::validates_inclusion_of :type
  # - hash: {key => value} == {DisplayName => ClassName}
  def asset_types
    {'Text' => 'Text'}
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

