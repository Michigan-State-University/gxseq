class BlastIteration < ActiveRecord::Base
  belongs_to :blast_run
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature"
  has_many :hits, :inverse_of => :blast_iteration, :dependent => :delete_all
  has_one :best_hit, :class_name => "Hit", :conditions=> "hits.hit_num=1"
  delegate :blast_database, :to => :blast_run, :allow_nil => true
  delegate :taxon, :filepath, :name, :description, :name_with_description, :to => :blast_database, :allow_nil => true
  
  validates_presence_of :blast_run_id
  # accepts_nested_attributes_for :hits
end