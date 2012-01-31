
class Experiment < ActiveRecord::Base
  belongs_to :user
  belongs_to :taxon_version
  has_many :bioentries_experiments, :dependent => :destroy
  #has_many through is ignoring the set_primary_key definition. Need to fix this!
  #has_many :bioentries, :through => :bioentries_experiments
  has_many :bioentries, :finder_sql => 'select b.* from bioentries_experiments be left outer join bioentry b on be.bioentry_id = b.bioentry_id where be.experiment_id =#{id}'
  has_many :assets, :dependent => :destroy
  has_many :components
  has_many :peaks
  has_many :tracks
  #validates_presence_of :user
  validates_presence_of :assets
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

  def initialize_assets
    assets.each { |a| a.experiment = self }
  end
  
  def initialize_bioentries
  end
  
  def taxon_version_id=(tv_id)    
    if(tv_id.to_i == self.taxon_version_id)
      logger.info "\n\nTaxon Version UNCHANGED\n\n"
      return super(tv_id)
    end
    tv = TaxonVersion.find(tv_id)
    self.bioentries_experiments.destroy_all
    tv.bioentries.each do |b|
      self.bioentries_experiments.build(:bioentry => b,:sequence_name => b.accession,:experiment => self)
    end
    
    super(tv_id)
  end
  
  def initialize_experiment
    puts "Initializing Experiment #{Time.now}"
    self.remove_asset_data
    self.load_asset_data
    puts "Finished Initialization #{Time.now}"
  end
  handle_asynchronously :initialize_experiment
  
  def get_chrom(bioentry_id)
    be = self.bioentries_experiments.where(:bioentry_id=>bioentry_id).first
    if(be)
      be.sequence_name
    else
      nil
    end
  end
  
  def display_name
    self.name
  end
  
  def display_info
    "#{display_name} - [#{bioentries.collect(&:species_name).join(",")}]"
  end
  
  def detailed_display_info
    "#{self.class.name}: #{display_name} - [#{bioentries.collect(&:species_name).join(",")}]"
  end
  
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
  
  def get_chrom_file
    chr = Tempfile.new("chrom.sizes")
    bioentries_experiments.each do |be|
      chr.puts "#{be.sequence_name} #{be.bioentry.length}"
    end 
    chr.flush
    return chr
  end
  
  ##Generalized methods (should be specialized in subclass)  
  def summary_data(start,stop,num,chrom)
  end
  
  def create_tracks
  end
   
  def load_asset_data
    puts "Loading Asset Data - #{Time.now}"
    assets.each{|a| a.load_data}
  end
  
  def remove_asset_data
    puts "Removing Asset Data - #{Time.now}"
    assets.each{|a| a.remove_data}
  end
  
  def asset_types
    #override in sub-class - hash: {key => value} == {DisplayName => ClassName}
    {'Text' => 'txt'}
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

