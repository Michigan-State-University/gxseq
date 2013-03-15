class Gene < Seqfeature
  #has_many :gene_models, :inverse_of => :gene
  before_validation :initialize_associations
  validates_associated :gene_models
  validate :check_locus_tag
  accepts_nested_attributes_for :gene_models, :allow_destroy => true
  
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
  
  def name
    self.gene.nil? ? locus_tag.value : self.gene.value
  end
  
  ## Override text index methods to return a combination of attributes from gene, cds and mrna
  ## We want to include 'product' and 'function' from any mrna or cds that belong to this gene
  ##
  # returns uniq 'gene names; products; functions; and synonyms' for all gene models
  def indexed_description
    names,prods,funcs,syns = [gene.try(:value)],[product.try(:value)],[function.try(:value)],[gene_synonym.try(:value)]
    gene_models.each do |gm|
      ['cds','mrna'].each do |feature|
        prods << gm.send(feature).try(:product_assoc).try(:value)
        funcs << gm.send(feature).try(:function_assoc).try(:value)
      end
    end
    [names.compact.uniq,prods.compact.uniq,funcs.compact.uniq,syns.compact.uniq].flatten.join("; ").presence
  end
  # returns uniq searchable attributes and any blast results for gene and function/product from all gene models
  def indexed_full_description
    vals = [search_qualifiers.map(&:value)]
    gene_models.each do |gm|
      ['cds','mrna'].each do |feature|
        vals << gm.send(feature).try(:product_assoc).try(:value)
        vals << gm.send(feature).try(:function_assoc).try(:value)
      end
    end
    [vals,blast_description].flatten.compact.uniq.join('; ').presence
  end
  # returns uniq products for all gene models
  def indexed_product
    vals = [product.try(:value)]
    gene_models.each do |gm|
      vals << gm.cds.try(:product_assoc).try(:value)
    end
    vals.compact.uniq.join("; ").presence
  end
  # returns uniq functions for all gene models
  def indexed_function
    vals = [function.try(:value)]
    gene_models.each do |gm|
      vals << gm.mrna.try(:function_assoc).try(:value)
    end
    vals.compact.uniq.join("; ").presence
  end
  # returns uniq protein_ids for all gene models
  def indexed_protein_id
    vals = []
    gene_models.each do |gm|
      vals << gm.cds.try(:protein_id_assoc).try(:value)
    end
    vals.compact.uniq.join("; ").presence
  end
  # returns uniq transcript_ids for all gene models
  def indexed_transcript_id
    vals = []
    gene_models.each do |gm|
      vals << gm.mrna.try(:transcript_id_assoc).try(:value)
    end
    vals.compact.uniq.join("; ").presence
  end
  # returns an array of all possible start locations in this gene
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
    #TODO: test this method against new inverse_of association setting
    self.gene_models.each{|gm| gm.gene=self; gm.bioentry=self.bioentry}
    super
  end
  
  # validate uniqueness and format of locus_tag before saving
  def check_locus_tag
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

