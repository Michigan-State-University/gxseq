class BlastRun < ActiveRecord::Base
  belongs_to :blast_database
  belongs_to :assembly
  belongs_to :user
  has_many :blast_reports, :dependent => :destroy
  delegate :taxon, :filepath, :name, :description, :name_with_description, :to => :blast_database, :allow_nil => true
  serialize :parameters, Hash
  validates_presence_of :blast_database
  # If there is no assembly we assume a one-off and will follow quota limits
  before_create :enforce_limit, :unless => :assembly_id
  @@recent_limit = 15
  
  # Check runs by user_id and enforce storage quota for all with nil assembly_id
  # Removes the oldest run by id if storage limit is reached
  def enforce_limit
    runs = BlastRun.where{user_id==my{self.user_id}}.where{assembly_id==nil}.order('id asc')
    if(runs.count >= @@recent_limit)
      runs.first.destroy
    end
  end
  # returns the recent runs quota set in class
  def self.recent_limit
    @@recent_limit
  end
  # returns the recent runs quota set in class
  def self.recent_limit=(new_limit)
    @@recent_limit=new_limit
  end
  # runs a blast using the supplied options and sequence
  # returns Bio::Blast::Report
  def self.local_blast(opts={})
    blastpath = APP_CONFIG[:blast_path]+'/blastall'
    return false if (program=opts[:program]).blank?
    return false if (sequence=opts[:sequence]).blank?
    # Try to find file in default directory or on the system
    if File.exist?("#{RAILS_ROOT}/lib/data/blast_db/#{opts[:filepath]}")
      path_to_database="#{RAILS_ROOT}/lib/data/blast_db/#{opts[:filepath]}"
    elsif File.exist?(opts[:filepath])
      path_to_database = opts[:filepath]
    else
      return false
    end
    # defaults
    matrix=opts[:matrix]||'BLOSUM62'
    evalue=opts[:evalue]||10
    hits=opts[:hits]||25
    format=opts[:format]||7
    
    local_blast_factory = Bio::Blast.local(
      program,
      path_to_database,
      "-M #{matrix} -e #{evalue} -v #{hits} -b #{hits} -m #{format}",
      blastpath
    )
    return local_blast_factory.query(sequence)
  end
end