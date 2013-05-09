class Track < ActiveRecord::Base
  belongs_to :assembly
  belongs_to :experiment
  has_many :track_configurations, :dependent => :destroy

  def name
    'Generic Track'
  end
  # creates tracks for all database items.
  # returns total number of tracks in database
  def self.create_all
    Experiment.all.each do |experiment|
      experiment.create_tracks
    end
    Assembly.all.each do |assembly|
      assembly.create_tracks
    end
    return Track.count
  end
  
  def root_path
    ENV['RAILS_RELATIVE_URL_ROOT']
  end
  
  def custom_config
    ""
  end
  
  def type
    "type  		: '#{self.class.name}',"
  end
  
  def iconCls
    'silk_bricks'
  end
  
end


# == Schema Information
#
# Table name: tracks
#
#  id            :integer(38)     not null, primary key
#  type          :string(255)
#  bioentry_id   :integer(38)
#  experiment_id :integer(38)
#  created_at    :datetime
#  updated_at    :datetime
#

