# == Schema Information
#
# Table name: blast_databases
#
#  created_at        :datetime
#  data_content_type :string(255)
#  data_file_name    :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#  description       :string(255)
#  filepath          :string(255)
#  group_id          :integer
#  id                :integer          not null, primary key
#  link_ref          :string(255)
#  name              :string(255)
#  taxon_id          :string(255)
#  updated_at        :datetime
#

class BlastDatabase < ActiveRecord::Base
  has_many :blast_reports
  has_many :assemblies, :through => :blast_runs
  has_many :blast_runs
  belongs_to :taxon, :class_name => "Biosql::Taxon"
  belongs_to :group
  validates_presence_of :name
  def name_with_description
    "#{name} - #{description}"
  end
end
