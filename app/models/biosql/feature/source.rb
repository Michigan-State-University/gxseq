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

class Biosql::Feature::Source < Biosql::Feature::Seqfeature
  #TODO: comment,refactor and condense multiple methods
  def label
    generic_label
  end
  #
  def label_type
    generic_label_type
  end
  
  def generic_label
    #A generic label to display for this source in a dropdown i.e. Chr 1, mitochondrion or plasmid xyz
    (chromosome || organelle || plasmid || mol_type || 'Unknown').to_s
  end
  
  def generic_label_type
    #A generic label to display for this source in a dropdown i.e. Chr 1, mitochondrion or plasmid xyz
    if chromosome
      return "Chr"
    elsif organelle
      return "Organelle"
    elsif plasmid
      return "Plasmid"
    elsif mol_type
      return "MolType"
    else
      return ""
    end
  end
end
