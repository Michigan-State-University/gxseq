# == Schema Information
#
# Table name: seqfeature
#
#  bioentry_id    :integer          not null
#  created_at     :datetime
#  display_name   :string(64)
#  rank           :integer          default(0), not null
#  seqfeature_id  :integer          not null, primary key
#  source_term_id :integer          not null
#  type_term_id   :integer          not null
#  updated_at     :datetime
#

class Biosql::Feature::Cds < Biosql::Feature::Seqfeature
  # do not autosave or we will infinite loop, gene_model auto-saves mrna and cds
  has_one :gene_model, :inverse_of => :cds, :autosave => false
  def name
    'CDS'
  end
  def display_type
    'CDS'
  end
  # returns protein sequence updated to reflect variation identified in sample
  def variant_protein_sequence(sample_id,opts={})
    return Bio::Sequence::NA.new(variant_na_sequence(sample_id,opts)).translate(1, bioentry.taxon.genetic_code || 1)
  end
end
