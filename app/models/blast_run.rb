# == Schema Information
#
# Table name: blast_runs
#
#  assembly_id       :integer
#  blast_database_id :integer
#  db                :string(255)
#  id                :integer          not null, primary key
#  parameters        :text
#  program           :string(255)
#  reference         :string(500)
#  user_id           :integer
#  version           :string(255)
#

class BlastRun < ActiveRecord::Base
  belongs_to :blast_database
  belongs_to :assembly
  belongs_to :user
  has_many :blast_reports, :dependent => :delete_all ## Deprecated
  has_many :blast_iterations, :dependent => :delete_all
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
    path_to_database="#{RAILS_ROOT}/lib/data/blast_db/#{opts[:filepath]}"

    # defaults
    matrix=opts[:matrix]||'BLOSUM62'
    evalue=opts[:evalue]||10
    hits=opts[:hits]||25
    format=opts[:format]||7
    blast_params="-M #{matrix} -e #{evalue} -v #{hits} -b #{hits} -m #{format}"
    if program == 'blastx'
      blast_params+=" -f 14 -F \"m S\""
      #blast_params+=" -F \"m S\""
    end
    local_blast_factory = Bio::Blast.local(
      program,
      path_to_database,
      blast_params,
      blastpath
    )
    return local_blast_factory.query(sequence)
  end
  
  def self.populate_blast_iteration(blast_run_id=nil,iteration=nil,seqfeature_id=nil,load_options=nil)
    load_options ||= {}
    # blast_iteration = self.blast_iterations.build(
    blast_iteration_id = BlastIteration.fast_insert(
      :blast_run_id => blast_run_id,
      :query_id => iteration.query_id,
      :query_def => iteration.query_def,
      :query_len => iteration.query_len,
      :seqfeature_id => seqfeature_id
    )
    
    iteration.hits.each do |hit|
      if load_options[:limit_hits]
        next if hit.num.to_i > load_options[:limit_hits].to_i
      end
      
      if(load_options[:remove_splice])
        accession = hit.accession.split(".")[0]
      end
      blast_hit_id = Hit.fast_insert(
        :blast_iteration_id => blast_iteration_id,
        :accession => hit.accession,
        :definition => hit.definition.length > 4000 ? hit.definition.slice(0..3999) : hit.definition,
        :length => hit.len,
        :hit_num => hit.num
      )
      
      hit.hsps.each do |hsp|
        Hsp.create(
          :hit_id => blast_hit_id,
          :bit_score => hsp.bit_score,
          :score => hsp.score,
          :query_from => hsp.query_from,
          :query_to => hsp.query_to,
          :hit_from => hsp.hit_from,
          :hit_to => hsp.hit_to,
          :query_frame => hsp.query_frame,
          :hit_frame => hsp.hit_frame,
          :identity => hsp.identity,
          :positive => hsp.positive,
          :gaps => hsp.gaps,
          :align_length => hsp.align_len,
          :evalue => hsp.evalue.to_f,
          :query_seq => hsp.qseq,
          :hit_seq => hsp.hseq,
          :midline => hsp.midline
        )
      end
    end
    
    if load_options[:test]
      raise "test option supplied"
    end
  end
end
