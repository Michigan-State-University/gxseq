class Track < ActiveRecord::Base
  belongs_to :taxon_version
  belongs_to :experiment
  has_many :track_configurations, :dependent => :destroy

  def name
    'Generic Track'
  end
  
  def self.create_all
    Experiment.all.each do |experiment|
      experiment.create_tracks
    end
    TaxonVersion.all.each do |taxon_version|
      taxon_version.create_tracks
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

