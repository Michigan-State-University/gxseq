class Gene < Seqfeature
  has_many :gene_models
  accepts_nested_attributes_for :gene_models, :allow_destroy => true
  validates_associated :gene_models
  before_validation :initialize_associations
  validate :check_locus_tag
  
  def self.find_by_locus_tag(locus="")
    self.find_all_by_locus_tag(locus).first
  end
  
  def self.find_all_by_locus_tag(locus="")
    Gene.joins(:qualifiers=>:term).where(:term=>{:name=>'locus_tag'}).where(:qualifiers=>{:value=>locus}).includes(:bioentry, :locations, :type_term, :qualifiers=>:term)
  end
  
  def representative_gene_model
    gene_models.first(:order => "(end_pos - start_pos) desc")
  end
  
  def display_type
    'Gene'
  end
  
  def display_name
    self.gene.nil? ? "-" : self.gene.value
  end
  
  def name
    self.gene.nil? ? locus_tag.value : self.gene.value
  end
  
  def function
     qualifiers.each do |q|
        if q.term.name == 'function'
           return q
        end
     end
     return nil
  end
  
  def gene_synonyms
    a = []
     qualifiers.each do |q|
        if q.term.name == 'gene_synonym'
           a<<q
        end
     end
     return a
  end
  
  def possible_starts(padding=300)
    starts=[]
    seq = bioentry.biosequence.seq[location.start_pos-(padding+1),(location.end_pos-location.start_pos)+(padding+1)]
    bioseq = Bio::Sequence::NA.new(seq)
    if(location.strand)
      bioseq.window_search(3,3) do |s,p|
        if s.downcase=='atg'
          starts<< p
        end
      end
    else
      bioseq.reverse_complement!
      bioseq.window_search(3,3) do |s,p|
        if s.downcase=='atg'
          starts<< seq.length-(p+3) #convert back to forward coordinates
        end
      end
    end
    return starts
  end
  
  def initialize_associations
    logger.info "\n\nStart validating GENE\n\n"
    self.gene_models.each{|gm| gm.gene=self; gm.bioentry=self.bioentry}
    logger.info "\n\n Before Super\n\n"
    super
    logger.info "\n\n-done validating GENE\n\n"
  end
  
  def check_locus_tag
    logger.info "\n\nCHECKING LOCUS TAG = GENE\n\n"
    if(self.locus_tag)
      if(self.locus_tag.value.match(/\s/))
        self.errors.add("locus_tag", "cannot have white space")
        return false
      end
       this_id = self.seqfeature_id
       others = Gene.includes([:qualifiers => :term],:bioentry).where(:bioentry_id => self.bioentry_id).where(:qualifiers => {:term => {:name => 'locus_tag'}}).where{seqfeature.seqfeature_id != this_id}.where(:qualifiers => {:value => self.locus_tag.value}) 
      if(others.empty?)
        return true
      else
        self.errors.add("locus_tag", "already taken. Choose a unique locus_tag or add models to the existing Gene: <a href='genes/#{others.first.id}' target=#>#{others.first.name}</a>")
        return false
      end
    end
    return true
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

