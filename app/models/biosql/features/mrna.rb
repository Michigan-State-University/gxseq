class Mrna < Seqfeature
  # do not autosave or we will infinite loop, gene_model auto-saves mrna and cds
  has_one :gene_model, :inverse_of => :mrna, :autosave => false
  def name
    'mRNA'
  end
  def display_type
    'mRNA'
  end
end
# == Schema Information
#
# Table name: sg_seqfeature
#
#  oid            :integer(38)     not null, primary key
#  rank           :integer(9)      not null
#  display_name   :string(64)
#  ent_oid        :integer(38)     not null
#  type_trm_oid   :integer(38)     not null
#  source_trm_oid :integer(38)     not null
#  deleted_at     :datetime
#  updated_at     :datetime
#

