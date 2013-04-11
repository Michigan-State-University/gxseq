class Bio::Feature::Source < Bio::Feature::Seqfeature
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

