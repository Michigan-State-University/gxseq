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

class Biosql::Feature::Seqfeature < ActiveRecord::Base
  # TODO: Refactor some methods in this class, its growing too large. Maybe a Search module
  set_table_name "seqfeature"
  set_primary_key :seqfeature_id
  set_sequence_name "SEQFEATURE_SEQ"
  set_inheritance_column :display_name
  has_paper_trail :meta => {
    :parent_id => Proc.new { |s| s.respond_to?(:gene_model) ? s.try(:gene_model).try(:gene_id) : nil},
    :parent_type => Proc.new { |s| s.respond_to?(:gene_model) ? s.try(:gene_model).try(:gene).try(:class).try(:name): nil}
  }
  belongs_to :bioentry, :class_name => "Biosql::Bioentry"
  belongs_to :type_term, :class_name => "Term", :foreign_key => "type_term_id"
  belongs_to :source_term, :class_name => "Term", :foreign_key =>"source_term_id"
  has_many :seqfeature_dbxrefs, :class_name => "SeqfeatureDbxref", :foreign_key => "seqfeature_id", :dependent  => :delete_all
  has_many :object_seqfeature_paths, :class_name => "SeqfeaturePath", :foreign_key => "object_seqfeature_id", :dependent  => :delete_all
  has_many :subject_seqfeature_paths, :class_name => "SeqfeaturePath", :foreign_key => "subject_seqfeature_id"
  has_many :object_seqfeature_relationships, :class_name => "SeqfeatureRelationship", :foreign_key => "object_seqfeature_id", :dependent  => :delete_all
  has_many :subject_seqfeature_relationships, :class_name => "SeqfeatureRelationship", :foreign_key => "subject_seqfeature_id"
  has_many :locations, :dependent  => :delete_all
  #extensions
  has_many :feature_counts
  has_many :blast_reports, :dependent => :destroy ##Deprecated
  has_many :blast_iterations, :dependent => :destroy
  has_many :blast_reports_without_report, :class_name => "BlastReport", :select => [:id,:hit_acc,:hit_def,:seqfeature_id,:blast_run_id]
  has_many :favorite_seqfeatures, :foreign_key => :favorite_item_id
  has_many :favorite_users, :through => :favorite_seqfeatures, :source => :user
  
  has_many :qualifiers, :include => :term, :class_name => "SeqfeatureQualifierValue",
    :order => "term.ontology_id desc,term.name,seqfeature_qualifier_value.rank",
    :dependent  => :delete_all,
    :inverse_of => :seqfeature,
    :after_remove => :update_assoc_mem
  
  has_many :bubble_qualifiers, :include => :term, :class_name => "SeqfeatureQualifierValue",
    :conditions => "lower(term.name) in ('#{(APP_CONFIG[:bubble_up_terms]||[]).join("','")}')"
  
  # Use the scope for counting or conditions on qualifiers
  # DO NOT mix with eager load on SeqfeatureQualifierValue table or results are limited to the supplied qualifier
  scope :with_qualifier, lambda {|term_name| joins{qualifiers.term}.where{lower(qualifiers.term.name)== my{term_name.downcase}}}
  # For index eager loading we add gene_models here but only Gene features will have gene_models
  # TODO: Test this for side effects against create/update gene
  has_many :gene_models, :foreign_key => :gene_id, :inverse_of => :gene
  
  # scope
  scope :with_locus_tag, lambda { |locus_tag|
    { :include => [:qualifiers => [:term]], :conditions => "upper(seqfeature_qualifier_value.value) = '#{locus_tag.upcase}'"}
  }
  # validations
  accepts_nested_attributes_for :qualifiers, :allow_destroy => true, :reject_if => lambda { |q| (q[:id] && Biosql::SeqfeatureQualifierValue.find(q[:id]).term.name =='locus_tag') || (q[:value].blank?) }
  accepts_nested_attributes_for :locations, :allow_destroy => true
  validates_presence_of :locations, :message => "Must have at least 1 location"
  validates_presence_of :bioentry
  validates_associated :qualifiers
  validates_associated :locations
  #TODO: deprecate and remove all rank columns
  #validates_uniqueness_of :rank, :scope => [:bioentry_id, :type_term_id, :source_term_id]
  before_validation :initialize_associations
  # Update in memory assoc of delete. This is done for updates but not deletes TODO Investigate bug fixes in rails 3.1/3.2 and test inverse of
  def update_assoc_mem(q)
    self.qualifiers -= [q]
  end

  ## CLASS METHODS
  
  # Use sunspot search to return a type_term_id facet for all seqfeatures with a given assembly_id
  def self.facet_types_with_expression_and_assembly_id(assembly_id)
    assembly = Assembly.find_by_id(assembly_id)
    self.search(:include => :feature_counts) do
      with(:assembly_id, assembly.id)
      any_of do
        assembly.samples.each do |sample|
          dynamic(:normalized_counts) do
            without "sample_#{sample.id}", nil
          end
          dynamic(:counts) do
            without "sample_#{sample.id}", nil
          end
          dynamic(:unique_counts) do
            without "sample_#{sample.id}", nil
          end
        end
      end
      facet(:type_term_id)
    end
  end
  # Use sunspot search to return a qualifier term_ids facet for all seqfeatures with a given assembly_id
  def self.facet_qualifier_terms_by_type_and_assembly_id(type_term_id,assembly_id)
    assembly = Assembly.find_by_id(assembly_id)
    self.search do
      with :type_term_id, type_term_id
      with :assembly_id, assembly.id
      facet :qualifier_term_ids
    end
  end
  def get_qualifier_idx_term_ids
    assembly_id = bioentry.assembly_id
    rows = self.class.facet_qualifier_terms_by_type_and_assembly_id(type_term_id,assembly_id).facet(:qualifier_term_ids).rows
    rows.collect{|r|"term_#{r.value}"}
  end
  # Convenience method for Re-indexing a subset of features
  def self.reindex_all_by_id(seqfeature_ids,batch_size=50)
    puts "Re-indexing #{seqfeature_ids.length} features"
    progress_bar = ProgressBar.new(seqfeature_ids.length)
    seqfeature_ids.each_slice(batch_size) do |id_batch|
      Sunspot.index self.includes(
        :bioentry, :feature_counts, :locations, :favorite_users,
        :qualifiers,
        :blast_iterations => [:best_hit => :best_hsp_with_scores]
      ).where{seqfeature_id.in(my{id_batch})}
      progress_bar.increment!(id_batch.length)
      if((progress_bar.count%10000)==0)
        Sunspot.commit
      end
    end
    Sunspot.commit
  end

  # return all seqfeatures with a single locus tag
  def self.find_all_by_locus_tag(locus="")
   find_all_with_locus_tags(Array(locus))
  end
  # return all seqfeatures matching a list of locus tags (limit list size to <= 999 if using oracle adapter)
  def self.find_all_with_locus_tags(locus)
    self.joins(:qualifiers=>:term).where{qualifiers.term.name=='locus_tag'}.where{upper(qualifiers.value).in(locus.map(&:upcase))}
  end
  # return all seqfeatures matching a list of qualifier values for the given key (limit list size to <= 999 if using oracle adapter)
  def self.find_all_with_qualifier_values(key,values,opts={})
    use_case = opts[:case_sensitive]||false
    if(use_case)
      self.joins(:qualifiers=>:term).where{qualifiers.term.name==key}.where{qualifiers.value.in(values)}
    else
      self.joins(:qualifiers=>:term).where{qualifiers.term.name==key}.where{upper(qualifiers.value).in(values.map(&:upcase))}
    end
  end
  # return a list of seqfeatures overlapping a particular region on a bioentry
  # Optional types[] array will limit results to the supplied types
  def self.find_all_by_location(start=1, stop=2,bioentry_id=nil,types=[])
    features = self.order('type_term_id')
      .includes(:locations, :type_term, [:qualifiers => [:term]])
      .where{(seqfeature.bioentry_id==my{bioentry_id}) & (location.start_pos < stop) & (location.end_pos > start)}
    unless types.empty?
      features = features.where{qualifiers.term.in(Array(types)) }
    end
    features
  end
  
  # returns terms that should not be indexed or displayed in search results
  def self.excluded_search_terms
    APP_CONFIG[:excluded_search_terms] || []
  end
  
  ## INSTANCE METHODS
  def related_versions
    vers = Version.where{parent_id == my{self.seqfeature_id}}.where{parent_type == my{self.class.name}} + self.versions
    vers.flatten.compact.uniq.sort{|a,b|b.created_at<=>a.created_at}
  end
  # generates a Seqfeature scope with all features having the same locus tag as self.
  # self will be included in the result
  def find_related_by_locus_tag
    return [self] if self.locus_tag.nil?
    return Biosql::Feature::Seqfeature.find_all_by_locus_tag(self.locus_tag.value)
  end
  ## returns display name for this feature. May be overriden in sub-class for custom types
  def label
    if locus_tag
      locus_tag.value
    else
      'no locus'
    end
  end
  # returns additional label information.
  # override in sub-class e.g. label=5 label_type = chromosome
  def label_type
    ''
  end
  # returns name of feature type for display. Can be overriden e.g. "mRNA"
  def display_type
   self.type_term.name
  end
  # returns display_type for use by versions changelog.
  def display_data
    "#{display_type}:"
  end
  # All annotation attributes for display / search
  def search_qualifiers
    qualifiers.reject{|q| Biosql::Feature::Seqfeature.excluded_search_terms.include?(q.term.name) }
  end

  # # All attributes from custom ontologies
  # def custom_qualifiers
  #   qualifiers.select{|q| q.term.ontology_id != Biosql::Term.ano_tag_ont_id}
  # end
  ### SQV types - allows for quick reference through eager load of :qualifiers
  # NOTE: These could be converted to STI classes but the table has no primary key
  # single sqv
  ['parent','chromosome','organelle','plasmid','mol_type', 'locus_tag','gene','gene_synonym','product','function','codon_start','protein_id','transcript_id','ec_number'].each do |sqv|
  define_method sqv.to_sym do
    qualifiers.each do |q|
        if q.term&&q.term.name.downcase == sqv
           return q
        end
     end
     return nil
   end
  end
  # multiple sqvs
  ['db_xref','note'].each do |sqv|
    define_method (sqv+'s').to_sym do
      sqv_array = []
      qualifiers.each do |q|
        if q.term&&q.term.name == sqv
          sqv_array << q
        end
      end
      return sqv_array
    end
  end
  # custom sqv, id is reserved
  def id_sqv
    qualifiers.each do |q|
      return q if q.term&&q.term.name.downcase == 'id'
    end
  end
  
  def strand
   self.locations.first ? self.locations.first.strand : 1
  end

  def min_start
   locations.map(&:start_pos).min
  end

  def max_end
   locations.map(&:end_pos).max
  end
  # Class method passed locations
  def self.na_sequence(locations=[],bioentry)
    seq = ""
    return seq if locations.empty?
    locations.each do |l|
      seq += bioentry.biosequence_without_seq.get_seq(l.start_pos-1, (l.end_pos-l.start_pos)+1)||''
    end
    return (locations.first.strand.to_i == 1) ? seq : Bio::Sequence::NA.new(seq).complement!.to_s.upcase
  end
  # returns concatenated na_sequence for locations
  def na_sequence
    self.class.na_sequence(self.locations,self.bioentry)
  end
  # returns protein sequence converted from na
  def protein_sequence
    return Biosql::Biosequence.to_protein(na_sequence,codon_start ? codon_start.value : 1,bioentry.taxon.genetic_code)
  end

  def length
    max_end - min_start
  end
  
  # creates a new locus tag for this seqfeature
  # does nothing if one already exists
  def find_or_create_locus_tag(locus_value)
    return self.locus_tag || Biosql::SeqfeatureQualifierValue.create(
      :seqfeature_id => self.id,
      :term_id => Biosql::Term.locus_tag.id,
      :rank => 1,
      :value => locus_value
    )
  end
  # return a genbank formatted location string
  def genbank_location
    text = ""
    if(locations.size > 1)
      text = "join(#{locations.collect(&:to_s).join(",")})"
    elsif(!locations.empty?)
      text = locations.first.to_s
    else
      text = "0..0"
    end
    if(locations.first.try(:strand).try(:to_i) == -1)
      text = "complement(#{text})"
    end
    return text
  end

  # return a genbank formatted entry ending with a newline
  # Name (start..end)
  #   qualifier=value
  #   qualifier2=value
  #
  # TODO: fix interpolate parameter. Should be options hash. 
  def to_genbank(allow_interpolate=true)
    text ="".ljust(6)+type_term.name.ljust(15)
    text += genbank_location.break_and_wrap_text(58,"\n",22,false)
    qualifiers.each do |q|
      text += ("/#{q.term.name}="+q.value).break_and_wrap_text(58,"\n",22)
      if(allow_interpolate&&q.term.name=='db_xref')
        text.gsub!(q.value,q.value(true))
      end
    end
    text+="\n"
    return text
  end
  
  # returns the fasta formatted header for this sequence
  def fasta_header(flanking,opts={})
     ">#{name} #{bioentry.display_info} from #{min_start - flanking} to #{max_end + flanking}"
  end
  
  # returns nucleic sequence updated to reflect variation identified in sample
  def variant_na_sequence(sample_id,opts={})
    return nil unless (v = Variant.find(sample_id))
    window = (opts[:window] || 0).to_i
    start = min_start-window
    stop = max_end+window
    seq = ""
    # start window
    if(window>0)
      seq += v.get_sequence(min_start-window,min_start-1,bioentry.id,opts[:sample],opts)
    end
    locations.each do |l|
      seq += v.get_sequence(l.start_pos,l.end_pos,bioentry.id,opts[:sample],opts)
    end
    # end window
    if(window>0)
      seq += v.get_sequence(max_end+1,max_end+window,bioentry.id,opts[:sample],opts)
    end
    #Not complemented to avoid seq coloring issues if opts[:html]
    if(opts[:html])
      return seq
    else
      return (locations.first.strand.to_i == 1) ? seq : Bio::Sequence::NA.new(seq).complement!.to_s.upcase
    end
  end
  # returns protein sequence updated to reflect variation identified in sample
  def variant_protein_sequence(sample_id,opts={})
    #nil by default
    return nil
  end
  # set rank and type_term before validation
  # creates a term for display_name if one cannot be found
  def initialize_associations
    if type_term_id.nil? && display_name
      seq_key_ont_id = Biosql::Term.seq_key_ont_id
      self.type_term_id = Biosql::Term.find_or_create_by_name_and_ontology_id(self.display_name,seq_key_ont_id).id
    end
    # TODO: Deprecate and remove all rank columns
    # if (!self.rank || rank==0) && self.bioentry_id && self.type_term_id
    #   self.rank = (self.bioentry.seqfeatures.where(:type_term_id => self.type_term_id).maximum(:rank)||0) + 1
    #   self.bioentry.seqfeatures.build(self)
    # end
  end

  # TODO: Move track data to Decorator or Exhibit maybe?
  def self.get_track_data(left,right,bioentry_id,opts={})
    max = (opts[:max]||5000).to_i
    data = []
    x = 100
    # NOTE: all gene_model features are left in to allow mRNA only (transcriptome) features to display
    #features = self.joins{[locations, bioentry]}.includes(:locations,:bioentry,:qualifiers).order("display_name").where("seqfeature.bioentry_id = #{bioentry_id} AND location.start_pos < #{right} AND location.end_pos > #{left} AND display_name not in ('#{GeneModel.seqfeature_types.push('Source').join("','")}')")
    features = self.joins{[locations, bioentry]}.includes(:locations,:bioentry,:qualifiers).where("seqfeature.bioentry_id = #{bioentry_id} AND location.start_pos < #{right} AND location.end_pos > #{left} AND display_name != 'Source'")
    if (f = features).count > max
      # narrow the scope until we select a small enough result
      while f.count > max
        f = features
        f = f.where("MOD(#{right}-location.start_pos,#{max})<#{x}")
        x = (x/2).floor
      end
      features = features.where("MOD(#{right}-location.start_pos,#{max})<#{x}")
      #features = features.limit(500)
      features << opts[:feature] if opts[:feature]
    end
    features.each do |fea|
      data.push(
      [
        nil,
        fea.id.to_i,
        (fea.strand.to_i == 1 ? "+" : "-"),
        'feature_parent',
        fea.min_start,
        (fea.max_end - fea.min_start).to_s,
        "no product",
        "",
        fea.id.to_s,
        "",
        fea.max_end
      ])
      fea.locations.each do |loc|
        data.push(
        [
          fea.id,
          loc.id.to_i,
          (loc.strand.to_i == 1 ? "+" : "-"),
          fea.display_type,
          loc.start_pos.to_i,
          (loc.end_pos.to_i - loc.start_pos.to_i).to_s,
          "no product",
          "",
          fea.id.to_s,
          "",
          loc.end_pos.to_i
        ])
      end
    end

    return data
  end
  # Expression search methods
  # TODO: Think about moving to new Expression or Search class instead
  # Set A vs Set B. Currently called by advanced_results action
  def self.ratio_search(current_ability,assembly_id,type_term_id,a_samples,b_samples,opts)
    # Default options
    sort_column = opts[:c]||'ratio'
    value_type = opts[:value_type]||'normalized_counts'
    order_d = (['ASC','asc','up'].include?(opts[:d]) ? :asc : :desc)
    # Infinite location setup
    infinity_offset = (opts[:infinite_order] == 'l' ? '-0.000001' : '0.000001' )
    # Order by sample ratio setup
    a_clause = [:div, [:sum, *a_samples.collect{|e| "sample_#{e.id}".to_sym}], "#{a_samples.length}"]
    b_clause = [:div, [:sum, *b_samples.collect{|e| "sample_#{e.id}".to_sym}], "#{b_samples.length}"]
    # Run base search with additional options
    base_search(current_ability,assembly_id,type_term_id,opts) do |s|
      # Minimum Count
      if opts[:min_sample_value]
        s.any_of do |any_a|
          a_samples.each do |sample|
            any_a.dynamic(value_type) do
              with("sample_#{sample.id}").greater_than opts[:min_sample_value]
            end
          end
        end
      end
      # Sorting
      case sort_column
      # dynamic 'sample_X' attribute
      when 'sample_a'
        s.dynamic(value_type) do
          order_by_function *a_clause,  order_d
        end
      when 'sample_b'
        s.dynamic(value_type) do
          order_by_function *b_clause,  order_d
        end
      when 'ratio'
        s.dynamic(value_type) do
          # div by zero must be handled otherwise results may be invalid
          # So, we add a very small number to numerator and denominator
          order_by_function :div, a_clause, [:sum,b_clause,infinity_offset],  order_d
        end
      # dynamic blast search
      when /blast_acc/
        s.dynamic(:blast_acc) do
          order_by sort_column.gsub('_acc',''), order_d
        end
      when /blast_id/
        s.dynamic(:blast_id) do
          order_by sort_column.gsub('_id',''), order_d
        end
      else
        s.order_by sort_column, order_d
      end
      # Custom settings
      yield (s)
    end
  end
  # Returns a csv string from a ratio search result. No header is present
  def self.ratio_search_to_csv(search,a_samples,b_samples,blast_runs,opts)
    result = []
    search.hits.each do |hit|
      data1 = [
        # Locus
        Array(hit.stored(:locus_tag_text)).first,
        # Definition
        (
        if opts[:multi_definition_type]
          opts[:multi_definition_type].collect{|definition| Array(hit.stored(definition+'_text')).first }.join(' | ')
        else
          Array(hit.stored(opts[:definition_type]+'_text')).first
        end
        )
      ]
      # Blast(s)
      data2 = blast_runs.collect{|blast_run| hit.stored(:blast_acc, "blast_#{blast_run.id}") }
      # Counts
      data3 = [
        # Set A
        "%.2f" % (a_avg=a_samples.inject(0.0){|sum, sample| sum+=(hit.stored(opts[:value_type],"sample_#{sample.id}")||0)}/a_samples.length),
        # Set B
        "%.2f" % (b_avg=b_samples.inject(0.0){|sum, sample| sum+=(hit.stored(opts[:value_type],"sample_#{sample.id}")||0)}/b_samples.length),
        # Ratio
        b_avg == 0 ? 'Inf' : "%.2f" % (a_avg/b_avg)
      ]
      result << (data1+data2+data3).to_csv
    end
    return result.join("")
  end
  # 1 column per sample. Currently called by results action
  def self.matrix_search(current_ability,assembly_id,type_term_id,samples,opts)
    # Default options
    sort_column = opts[:c]||'sum'
    value_type = opts[:value_type]||'normalized_counts'
    order_d = (['ASC','asc','up'].include?(opts[:d]) ? :asc : :desc)
    sample_symbols = samples.collect{|sample| "sample_#{sample.id}".to_sym}
    # begin the sunspot search definition
    base_search(current_ability,assembly_id,type_term_id,opts) do |s|
      # Sorting
      case sort_column
      # dynamic 'sample_X' attribute
      when /sample_/
        s.dynamic(value_type) do
          order_by sort_column, order_d
        end
      # dynamic blast search
      when /blast_acc/
        s.dynamic(:blast_acc) do
          order_by sort_column.gsub('_acc',''), order_d
        end
      when /blast_id/
        s.dynamic(:blast_id) do
          order_by sort_column.gsub('_id',''), order_d
        end
      # sum function
      when 'sum'
        s.dynamic(value_type) do
          order_by_function :sum, *sample_symbols,  order_d
        end
      # default
      else
        s.order_by sort_column, order_d
      end
      # Custom settings
      yield (s)
    end
  end
  # Returns a csv string for a matrix search result. No header is present
  def self.matrix_search_to_csv(search,samples,blast_runs,opts)
    result = []
    search.hits.each do |hit|
      data1 = [
        # Locus
        Array(hit.stored(:locus_tag_text)).first,
        # Definition
        (
        if opts[:multi_definition_type]
          opts[:multi_definition_type].collect{|definition| Array(hit.stored(definition+'_text')).first }.join(' | ')
        else
          Array(hit.stored(opts[:definition_type]+'_text')).first
        end
        )
      ]
      # Blast(s)
      data2 = blast_runs.collect{|blast_run| hit.stored(:blast_acc, "blast_#{blast_run.id}") }
      # Counts
      sum=0
      val=0
      data3 = []
      samples.each do |sample|
        val = hit.stored(opts[:value_type],"sample_#{sample.id}")
        sum += (val||0)
        data3 << val
      end
      data3 << sum
      result << (data1+data2+data3).to_csv
    end
    return result.join("")
  end
  
  def self.base_search(ability,assembly_id,type_term_id,opts={})
    # Find minimum set of id ranges accessible by current user
    # Set to -1 if no items are found. This will force empty search results
    authorized_assembly_ids = ability.authorized_assembly_ids
    authorized_assembly_ids=[-1] if authorized_assembly_ids.empty?
    assembly_id = -1 unless authorized_assembly_ids.include?(assembly_id.to_i)
    # Optional arguments
    locus_tag = opts[:locus_tag]
    keywords = opts[:keywords]
    multi_definition_type = opts[:multi_definition_type]
    definition_type = opts[:definition_type]
    favorites = opts[:favorites_filter]
    seqfeature_id = opts[:seqfeature_id]
    empty_filter = opts[:show_blank]
    blast_acc = opts[:blast_acc]
    # Begin search block
    self.search do |s|
      # Auth
      s.with :assembly_id, authorized_assembly_ids
      # limit to the current assembly
      s.with(:assembly_id, assembly_id.to_i)
      # limit to the supplied type
      unless type_term_id.blank?
        s.with(:type_term_id, type_term_id.to_i)
      end
      # Search Filters - locus_tag is an example
      unless locus_tag.blank?
        s.with :locus_tag, locus_tag
      end
      if(blast_acc)
        blast_acc.each do |key,value|
          unless value.blank?
            s.dynamic :blast_acc do
              with(key,value)
            end
          end
        end
      end
      # Text Search
      unless keywords.blank?
        if multi_definition_type
          s.fulltext keywords, :fields => [multi_definition_type.map{|s| s+'_text'},:locus_tag_text].flatten, :highlight => true
        else
          s.fulltext keywords, :fields => [definition_type+'_text', :locus_tag_text], :highlight => true
        end
      end
      # Remove empty      
      case empty_filter
      # don't show empty definitions
      when 'n'
        if multi_definition_type
          s.any_of do |any_s|
            multi_definition_type.each do |def_type|
              any_s.without def_type, nil
            end
          end
        else
          s.without definition_type, nil
        end
      # only show empty definitions
      when 'e'
        if multi_definition_type
          s.all_of do |all_s|
            multi_definition_type.each do |def_type|
              all_s.with def_type, nil
            end
          end
        else
          s.with definition_type, nil
        end
      end
      # Favorites
      case favorites
      when 'user'
        s.with :favorite_user_ids, ability.user_id
      when 'all'
        s.without :favorite_user_ids, nil
      end
      # scope to id
      # we use this search so we can insert a highlighted text result after an update
      if(seqfeature_id)
        s.with :id, seqfeature_id
      end
      # Any custom search settings
      yield(s)
    end
  end
  
  def correlated_search(ability,opts={})
    return nil if feature_counts.nil?
    total_feature_counts = feature_counts.accessible_by(ability).length
    value_type=opts[:value_type]||'normalized_count'
    per_page=opts[:per_page]||50
    page=opts[:page]||1
    x_sum = 0
    xsquare = 0
    ordered_counts = feature_counts.order("sample_id").accessible_by(ability)
    ordered_counts.each do |feature_count|
      x = feature_count.send(value_type).to_f
      x_sum += x
      xsquare += (x*x)
    end
    return nil if x_sum == 0
    sxx = xsquare - ((x_sum*x_sum)/total_feature_counts)
    
    sample_strings = ordered_counts.collect{|fc| "sample_#{fc.sample_id}".to_sym}
    sample_square = ordered_counts.collect{|fc| [:pow,"sample_#{fc.sample_id}".to_sym,'2']}
    sample_product = ordered_counts.collect{|fc| [:product,"#{fc.send(value_type).to_f}","sample_#{fc.sample_id}".to_sym]}
    # FIXME: Re-use of the clause leads to errors due to removal of first argument
    y_sum = [:sum,*sample_strings]
    y_sum_dup = [:sum,*sample_strings]
    y_square = [:sum,*sample_square]
    product = [:sum,*sample_product]
    sxy_clause = [:sub,product,[:div,[:product,y_sum_dup,"#{x_sum.round(4)}"],"#{total_feature_counts}"]]
    syy_clause = [:sub,y_square,[:div,[:pow,y_sum,'2'],"#{total_feature_counts}"]]
    denom_clause = [:product, [:sqrt,syy_clause],"#{Math.sqrt(sxx).round(4)}" ]
    my_assembly_id = self.bioentry.assembly_id.to_i
    my_type_term_id = self.type_term_id.to_i
    Biosql::Feature::Seqfeature.search do
      # Compute and order by correlation
      dynamic(value_type+'s') do
        # r2 
        order_by_function :pow, [:div, sxy_clause, denom_clause],'2', :desc
      end
      # limit to the current assembly
      with(:assembly_id, my_assembly_id)
      # limit to the supplied type
      with(:type_term_id, my_type_term_id)
      # Do not allow all zeroes in result
      any_of do
        dynamic(value_type+'s') do
          ordered_counts.each do |oc|
            with("sample_#{oc.sample_id}").greater_than(0)
          end
        end
      end
      # Paging
      paginate(:page => page, :per_page => per_page)
    end
  end
  # Returns the correlation between two hits with the same samples
  def get_correlation(compared_hit,f_counts,opts={})
    total_feature_counts = f_counts.length
    # Default to normalized values
    value_type=opts[:value_type]||'normalized_count'
    # Initialize the variables
    xsum = ysum = xsquare = ysquare = product = sxx = syy = sxy = r = 0
    # grab the counts for this hit
    compared_values = []
    ordered_values = []
    f_counts.each do |f_count|
      ordered_values.push(f_count.send(value_type).to_f)
      compared_values.push(compared_hit.stored(value_type+'s',"sample_#{f_count.sample_id}").to_f)
    end
    # Collect the sum and sum of squares
    ordered_values.zip(compared_values).each do |x,y|
      xsum += x
      ysum += y
      xsquare += (x*x)
      ysquare += (y*y)
      product += (x*y)
    end
    sxx = xsquare - ((xsum*xsum)/total_feature_counts)
    syy = ysquare - ((ysum*ysum)/total_feature_counts)
    return 0 if sxx==0 || syy ==0
    sxy = product - ((xsum*ysum)/total_feature_counts)
    # Return r squared the Pearsone Correlation Coefficient
    r =  ( sxy / (Math.sqrt(sxx)*Math.sqrt(syy)) )
    return r.round(4)
  end
  # Computes the sum of all samples for the supplied hit and feature_counts
  def get_sum(hit,f_counts,opts={})
    # Default to normalized values
    value_type=opts[:value_type]||'normalized_count'
    # Sum the counts
    f_counts.inject(0){|sum,f_count| sum+hit.stored(value_type+'s',"sample_#{f_count.sample_id}").to_f}.round(2)
  end
  # returns formatted counts for all coexpressed features
  # [{:id,:name,:description,:correlation,:sample1,:sample2,...}]
  def corr_search_to_matrix(corr_search,f_counts,opts={})
    value_type=opts[:value_type]||'normalized_count'
    results = []
    blast_run_terms = bioentry.assembly.blast_runs.each.map{|blast_run|"blast_#{blast_run.id}"}||[]
    anno_terms = get_qualifier_idx_term_ids||[]
    terms = blast_run_terms + anno_terms
    terms.sort!{|a,b| (APP_CONFIG[:term_id_order][a+'_order']||1).to_i <=> (APP_CONFIG[:term_id_order][b+'_order']||1).to_i  }
    corr_search.hits.each_with_index do |hit|
      desc = ''
      desc += terms.collect{|t| Array(hit.stored(t+'_text')).first}.compact.join(" | ")
      #desc += blast_run_texts.collect{|br| Array(hit.stored(br)).first}.compact.join("; ")
      item = {
        :id => hit.stored(:id),
        :locus => Array(hit.stored(:locus_tag_text)).first,
        :description => desc,
        :r => (r=get_correlation(hit,f_counts,opts)),
        :r2 => (r*r).round(4),
        :sum => (sum = get_sum(hit,f_counts,opts)),
        :avg => (sum / f_counts.length).round(2)
      }
      item[:values]=[]
      f_counts.each do |f_count|
        item[:values] << {:x => f_count.sample.name, :y => hit.stored(value_type+'s',"sample_#{f_count.sample_id}")}
        #item[f_count.sample.name]= hit.stored(value_type+'s',"sample_#{f_count.sample_id}")
      end
      results.push(item)
    end
    return results
  end
  
  protected
  ## Sunspot search definition
  ## TODO: Document Search attributes
  searchable(
    :include => [
      :bioentry, :feature_counts, :locations, :favorite_users,
      :qualifiers,
      :blast_iterations => [:best_hit => :best_hsp_with_scores]
    ]) do |s|
    # locus
    s.text :locus_tag_text, :stored => true do
     locus_tag.value if locus_tag
    end
    s.string :locus_tag, :stored => true do
      locus_tag.try(:value)
    end
    # STI type
    s.string :display_name
    # ID's
    s.integer :qualifier_term_ids, :references => Biosql::Term, :multiple => true  do
      search_qualifiers.map(&:term_id)
    end
    s.integer :id, :stored => true
    s.integer :bioentry_id, :stored => true
    s.integer :type_term_id, :references => Biosql::Term
    s.integer :source_term_id, :references => Biosql::Term
    s.integer :favorite_user_ids, :multiple => true, :stored => true
    s.integer :assembly_id, :stored => true do
      bioentry.assembly_id
    end
    # Position
    s.integer :strand, :stored => true
    s.integer :start_pos, :stored => true do
      min_start
    end
    s.integer :end_pos, :stored => true do
      max_end
    end
    # field names need to start with non numeric characters. Numbers cause solr query errors
    # dynamic feature expression
    s.dynamic_float :normalized_counts, :stored => true do
      feature_counts.inject({}){|h,x| h["sample_#{x.sample_id}"]=x.normalized_count;h}
    end
    s.dynamic_float :counts, :stored => true do
      feature_counts.inject({}){|h,x| h["sample_#{x.sample_id}"]=x.count;h}
    end
    s.dynamic_float :unique_counts, :stored => true do
      feature_counts.inject({}){|h,x| h["sample_#{x.sample_id}"]=x.unique_count;h}
    end
    # TODO: Add acts_as_taggable indexed tags for better search/filtering of e.g. [Transcription Factor] tag
    # # dynamic tags
    # s.dynamic_boolean :tags do
    # end
    # dynamic blast reports
    s.dynamic_string :blast_acc, :stored => true do
      blast_iterations.inject({}){|hash,report| hash["blast_#{report.blast_run_id}"]=report.best_hit.accession;hash}
    end
    s.dynamic_string :blast_id, :stored => true do
      blast_iterations.inject({}){|hash,report| hash["blast_#{report.blast_run_id}"]=report.id;hash}
    end
    s.dynamic_string :blast_evalue, :stored => true do
      blast_iterations.inject({}){|hash,report| hash["blast_#{report.blast_run_id}"]=report.best_hit.best_hsp_with_scores.evalue;hash}
    end
    # Fake dynamic blast text - defined for every blast_run on every seqfeature
    # These are baked into the class, so it needs to be reloaded when new BlastRuns are created
    # TODO: find alternative for dynamic full text search
    begin
      BlastRun.all.each do |blast_run|
        s.string "blast_#{blast_run.id}".to_sym do
          report = blast_iterations.select{|b| b.blast_run_id == blast_run.id }.first
          report ? report.best_hit.definition : nil
        end
        s.text "blast_#{blast_run.id}_text".to_sym, :stored => true do
          report = blast_iterations.select{|b| b.blast_run_id == blast_run.id }.first
          report ? report.best_hit.definition : nil
        end
      end
      # More fake dynamic text for annotations
      Biosql::Term.annotation_ontologies.each do |ont|
        ont.terms.each do |ont_term|
          next if Biosql::Feature::Seqfeature.excluded_search_terms.include?(ont_term.name)
          s.string "term_#{ont_term.id}".to_sym do
            a = self.qualifiers.select{|q| q.term_id == ont_term.id}.collect(&:value).join('; ')
            a.empty? ? nil : a
          end
          s.text "term_#{ont_term.id}_text".to_sym, :stored => true do
            a = self.qualifiers.select{|q| q.term_id == ont_term.id}.collect(&:value).join('; ')
            a.empty? ? nil : a
          end
        end
      end
    rescue => e
      puts "Could not define dynamic text in Seqfeature searchable definition. BlastRun and/or Term missing\n#{e}\n"
    end
  end
  
  @@term_names={}
  def self.idx_id_to_name(text_id)
    if @@term_names[text_id]
      return @@term_names[text_id]
    else
      if m = text_id.match(/blast_(\d+)/)
        @@term_names[text_id]=BlastRun.find_by_id(m[1]).try(:name) || ??
      elsif m = text_id.match(/term_(\d+)/)
        @@term_names[text_id]=Biosql::Term.find_by_term_id(m[1]).try(:name) || ??
      else
        return "??"
      end
    end
  end
end

Biosql::Feature::Seqfeature.store_full_sti_class = false
