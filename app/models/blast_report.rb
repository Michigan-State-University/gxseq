# == Schema Information
#
# Table name: blast_reports
#
#  blast_run_id  :integer
#  created_at    :datetime
#  hit_acc       :string(255)
#  hit_def       :string(4000)
#  id            :integer          not null, primary key
#  report        :text
#  seqfeature_id :integer
#  updated_at    :datetime
#

class BlastReport < ActiveRecord::Base
  belongs_to :blast_run
  belongs_to :seqfeature, :class_name => "Biosql::Feature::Seqfeature"
  serialize :report, Bio::Blast::Report
  delegate :blast_database, :to => :blast_run, :allow_nil => true
  delegate :taxon, :filepath, :name, :description, :name_with_description, :to => :blast_database, :allow_nil => true
  validates_presence_of :blast_run_id
  has_paper_trail :skip => :report
  
end
