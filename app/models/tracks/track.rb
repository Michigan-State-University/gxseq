class Track < ActiveRecord::Base
  belongs_to :bioentry
  has_many :track_configurations, :dependent => :destroy
  scope :with_bioentry, lambda { |id|
        { :conditions => { :bioentry_id => id } }
      }
  def name
    'Generic Track'
  end
  
  def self.create_all
    Experiment.all.each do |e|
      e.create_track
    end
    Bioentry.all.each do |b|
      b.create_tracks
    end
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

