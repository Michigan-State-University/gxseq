class Sequence < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  
  desc 'load FILE','Load genomic sequence into the database'
  method_options :database => 'Public', :verbose => false, :version => 1, :source_name => "EMBL/GenBank/SwissProt"
  method_options :transcriptome => false, :add_entry_feature => nil
  method_option :species
  method_option :strain
  method_option :division
  method_option :molecule_type
  def load(input_file)
    # setup
    version = options[:version]
    database = options[:database]
    verbose = options[:verbose]
    taxon_name = options[:taxon_name]
    division = options[:division]
    molecule_type = options[:molecule_type]
    source_name = options[:source_name]
    test_only = options[:test_only]
    is_transcriptome = options[:transcriptome]
    entry_feature = options[:add_entry_feature]
    species = options[:species]
    strain = options[:strain]
    species_id=options[:species_id]
    strain_id = options[:strain_id]
    entry_count = 0
    seq_key_terms = {}
    anno_tag_terms = {}
    qual_rank = {}
    feat_rank = {}
    bad_count = 0
    base = ActiveRecord::Base
    # grab the time for stats
    curr_time = Time.now
    task_start_time = Time.now
    # Parse input
    begin
      data = Bio::FlatFile.open(input_file,"r")
    rescue
      puts "*** Error parsing input *** \n#{$!}"
      exit 0
    end
    # Check file format
    supported_file_types= ['genbank','fasta']
    file_type = data.dbclass.name.gsub(/Bio::/,'').downcase.gsub(/format/,'')
    unless(supported_file_types.include?(file_type))
      raise "Unsupported file type #{file_type}\nPlease provide a #{supported_file_types.to_sentence(:last_word_connector => ' or ', :two_words_connector => ' or ')}"
    end
    # Setup namespace and source term
    bio_db = Biodatabase.find_or_create_by_name(database)
    seq_src_term = Term.find_or_create_by_name_and_ontology_id(source_name,Term.seq_src_ont_id)
    # Put this all in a transaction, just in case. We don't want partial bioentries
    begin
      Biodatabase.transaction do
        # Loop through each of the entries we receive from FlatFile iterator
        data.each do |entry|
          # Getting an empty entry at end of file so we skip it here          
          next if(entry.accession.blank? && entry.definition.blank? && entry.seq.length == 0 && entry.features.size == 0)          
          #create the accesion for this sequence based on accession, entry_id, and locus          
          entry_accession = get_entry_accession(entry,file_type)
          #update the counter
          entry_count +=1
          # grab the converted biosequence
          entry_bioseq = entry.to_biosequence
          # log
          puts "Working on entry #{entry_count}: #{(entry.definition.length > 75) ? entry.definition[0,74]+"..." : entry.definition}" if verbose          
          # Get Entry version
          if(entry.respond_to?(:version))
            entry_version = (entry.version.nil? ? 1 : entry.version)
          else
            entry_version = 1
          end
          # Get Taxon
          species_taxon, strain_taxon = get_entry_taxonomy(entry,{:species => species,:strain => strain,:species_id => species_id,:strain_id => strain_id})
          # Get Taxon Version
          if(is_transcriptome)
            taxon_version = Transcriptome.find_or_create_by_version_and_species_id_and_taxon_id(version,species_taxon.id,strain_taxon.id)
          else
            taxon_version = Genome.find_or_create_by_version_and_species_id_and_taxon_id(version,species_taxon.id,strain_taxon.id)
          end
          # link Biodatabase
          bio_db.taxons << species_taxon unless bio_db.taxons.include?(species_taxon)
          
          # get Division
          unless(entry_division = division || (entry.respond_to?(:division) ? entry.division : nil))
            puts "You must supply a 3 letter division="
            puts "The following table should help:"
            puts "\tPRI - primate sequences"
            puts "\tROD - rodent sequences"
            puts "\tMAM - other mammalian sequences"
            puts "\tVRT - other vertebrate sequences"
            puts "\tINV - invertebrate sequences"
            puts "\tPLN - plant, fungal, and algal sequences"
            puts "\tBCT - bacterial sequences"
            puts "\tVRL - viral sequences"
            puts "\tPHG - bacteriophage sequences"
            puts "\tSYN - synthetic sequences"
            puts "\tUNA - unannotated sequences"
            puts "\tEST - EST sequences (expressed sequence tags)"
            puts "\tPAT - patent sequences"
            puts "\tSTS - STS sequences (sequence tagged sites)"
            puts "\tGSS - GSS sequences (genome survey sequences)"
            puts "\tHTG - HTG sequences (high-throughput genomic sequences)"
            puts "\tHTC - unfinished high-throughput cDNA sequencing"
            puts "\tENV - environmental sampling sequences"
            raise "*** No division could be found\n"
          end
          
          # get alphabet
          unless(alphabet = entry_bioseq.molecule_type || molecule_type)
            puts "\tDNA - Genomic DNA: Sequence derived directly from the DNA of an organism. Note: The DNA sequence of an rRNA gene has this molecule type, as does that from a naturally-occurring plasmid."
            puts "\tRNA - Genomic RNA: Sequence derived directly from the genomic RNA of certain organisms, such as viruses."
            puts "\tpRNA - Precursor RNA: An RNA transcript before it is processed into mRNA, rRNA, tRNA, or other cellular RNA species."
            puts "\tmRNA - mRNA[cDNA]: A cDNA sequence derived from mRNA."
            puts "\trRNA - Ribosomal RNA: A sequence derived from the RNA in ribosomes. This should only be selected if the RNA itself was isolated and sequenced. If the gene for the ribosomal RNA was sequence, select Genomic DNA."
            puts "\ttRNA - Transfer RNA: A sequence derived from the RNA in a transfer RNA, for example, the sequence of a cDNA derived from tRNA."
            puts "\tother - Other-Genetic: A synthetically derived sequence including cloning vectors and tagged fusion constructs."
            puts "\tcRNA - RNA: A sequence derived from complementary RNA transcribed from DNA, mainly used for viral submissions."
            puts "\ttransRNA: A sequence derived from any transcribed RNA not listed above."
            puts "\ttmRNA - Tranfer-messenger RNA: A sequence derived from transfer-messenger RNA, which acts as a tRNA first and then an mRNA that encodes a peptide tag. If the gene for the tmRNA was sequenced, use genomic DNA."
            puts "\tncRNA - ncRNA: A sequence derived from other non-coding RNA not specified"
            raise "*** No molecule type found\n"
          end
          
          # Check for existing entry
          unless(bioentry = Bioentry.find_by_taxon_version_id_and_biodatabase_id_and_accession_and_version(taxon_version.id,bio_db.id,entry_accession,entry_version))
            # bioentry
            bioentry = bio_db.bioentries.new(
            :taxon_version => taxon_version,
            :taxon_id  => taxon_version.taxon_id,
            :name => entry_accession,
            :accession => entry_accession,
            :identifier => 0,
            :division => entry_division,
            :description => entry.definition,
            :version => entry_version
            )
            # biosequence
            bioseq = bioentry.build_biosequence(
            :version => entry_version,
            :length => entry_bioseq.length,
            :alphabet => alphabet,
            :seq  => entry.seq.upcase
            )
            # entry and bioseq are built and then saved to allow indexer lookup of bioseq in callback
            bioentry.save!
            #use our own internal id for bioentry->identifier
            bioentry.update_attribute(:identifier, bioentry.id)
            # New Entry Feature?
            if(entry_feature)
              type_term_id = Term.find_or_create_by_name_and_ontology_id(entry_feature,Term.seq_key_ont_id).id
              new_seqfeature_id=Seqfeature.fast_insert(
                :bioentry_id => bioentry.id,
                :type_term_id => type_term_id,
                :source_term_id => seq_src_term.id,
                :rank => 1,
                :display_name => entry_feature.downcase.camelize
              )
              Location.fast_insert(
                :seqfeature_id => new_seqfeature_id,
                :start_pos => 1,
                :end_pos => entry_bioseq.length,
                :strand => 1,
                :rank => 1,
                :term_id => type_term_id
              )
              locus_term_id = Term.find_or_create_by_name_and_ontology_id('locus_tag', Term.ano_tag_ont_id).id
              base.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
              VALUES(#{new_seqfeature_id},#{locus_term_id},'#{entry_accession}',1)")
            end
            # comment(s)
            if(entry_bioseq.comments.kind_of?(Array) && !entry_bioseq.comments.empty?)
              entry_bioseq.comments.each do |c|
                bioentry.comments.create(
                :comment_text => c,
                :rank  => bioentry.comments.size + 1
                )
              end
            elsif(entry_bioseq.comments.kind_of?(String) && !entry_bioseq.comments.empty?)
              bioentry.comments.create(
              :comment_text => entry_bioseq.comments,
              :rank => bioentry.comments.size + 1
              )
            end
            # bioentry dblinks
            b_dbx_rank = 1
            if(entry.gi && entry.gi.to_i > 0)
              new_xref= Dbxref.create(
              :dbname => "GI",
              :accession => entry.gi.gsub(/g|G|i|I\:/, "").to_i,
              :version => entry_version
              )
              #getting errors on first create attempt(from nil primary key?) so inserting manually
              #be_xref = BioentryDbxref.create(:bioentry_id => bioentry.id, :dbxref_id => new_xref.id, :rank => b_dbx_rank) 
              base.connection.execute("INSERT INTO bioentry_dbxref(bioentry_id,dbxref_id,rank) VALUES(#{bioentry.id},#{new_xref.id},#{b_dbx_rank})")        
              b_dbx_rank+=1
            end

            # references
            if(entry.respond_to?(:references))
              entry.references.each do |reference|        
                ref_authors = reference.authors.map{|a|a.gsub(/(\,)(\s)(\w)/,'\1\3')}.to_sentence unless reference.authors.nil?
                ref_location = "#{reference.journal ? reference.journal : 'Unpublished'}#{reference.volume.empty? ? '' : ' '+reference.volume}#{reference.issue.empty? ? '' : ' ('+reference.issue+'),'}#{reference.pages.empty? ? '' : ' '+reference.pages}#{reference.year.empty? ? '' : ' ('+reference.year+')'}"
                ref_crc = Zlib::crc32("#{ref_authors ? ref_authors : '<undef>'}#{reference.title ? reference.title : '<undef>'}#{ref_location}")
                unless (new_reference = Reference.find_by_crc(ref_crc))
                  # create dbxref
                  new_dbxref_id = nil
                  unless(reference.pubmed.nil? || reference.pubmed.empty?)
                    new_dbxref = Dbxref.create(
                    :dbname => "PUBMED",
                    :accession => reference.pubmed,
                    :version => 0  # NOTE: Not sure when to update reference version?
                    )
                    new_dbxref_id = new_dbxref.id
                  end
                  # create reference
                  new_reference = Reference.create(
                  :dbxref_id => new_dbxref_id,
                  :location => ref_location,
                  :title => reference.title,
                  :authors => ref_authors,
                  :crc => ref_crc
                  )
                end
                # link reference to bioentry
                bioentry.bioentry_references.create(
                :reference_id => new_reference.id,
                :start_pos => reference.sequence_position ? reference.sequence_position.split('-')[0] : 0,
                :end_pos => reference.sequence_position ? reference.sequence_position.split('-')[1] : bioentry.length,                
                :rank => bioentry.bioentry_references.size + 1
                )
              end
            end
            if(entry.respond_to?( :keywords ))
              # Bioentry Qualifier Values
              ## keywords
              rank = 1
              entry.keywords.each do |keyword|
                key_term = Term.find_or_create_by_name_and_ontology_id("keyword", Term.ano_tag_ont_id)
                bioentry.bioentry_qualifier_values.create(
                :term_id => key_term.id,
                :value => keyword,
                :rank => rank)
                rank +=1
              end
            end
            
            ## secondary accessions
            if entry_bioseq.secondary_accessions
              rank = 1
              entry_bioseq.secondary_accessions.each do |accession|
                acc_term = Term.find_or_create_by_name_and_ontology_id("secondary_accession", Term.ano_tag_ont_id)
                bioentry.bioentry_qualifier_values.create(
                :term_id => acc_term.id,
                :value => accession,
                :rank => rank)
                rank +=1
              end
            end
            
            if(entry.respond_to?(:date))
              ## date
              unless(entry.date.nil? || entry.date.empty?)
                bioentry.bioentry_qualifier_values.create(
                :term_id => Term.find_or_create_by_name_and_ontology_id("date_modified", Term.ano_tag_ont_id).id,
                :value => entry.date,
                :rank => 1)
              end
            end
            
            # Features
            if(entry.respond_to?(:features))
              printf "-features-\n" if verbose
              feature_count=0
              feat_rank.clear
              entry.features.each do |f|
                feature=f.clone
                feature_count+=1
                # term
                type_term_id=seq_key_terms["#{feature.feature}"] || (seq_key_terms["#{feature.feature}"] = Term.find_or_create_by_name_and_ontology_id(feature.feature,Term.seq_key_ont_id).id)      
                feat_rank["#{feature.feature}"]||=0
                feat_rank["#{feature.feature}"]+=1
                # seqfeature
                new_seqfeature_id=Seqfeature.fast_insert(
                :bioentry_id => bioentry.id,
                :type_term_id => type_term_id,
                :source_term_id => seq_src_term.id,
                :rank => feat_rank["#{feature.feature}"],
                :display_name => feature.feature.downcase.camelize
                )
                # location(s)
                # parse position text - fairly naive, may need updates for complicated locations
                strand = (feature.position=~/complement/ ? -1 : 1)
                rank = 1
                feature.position.scan(/(\d+)\.\.(\d+)/){ |l1,l2|
                  Location.fast_insert(
                  :seqfeature_id => new_seqfeature_id,
                  :start_pos => l1,
                  :end_pos => l2,
                  :strand => strand,
                  :rank => rank,
                  :term_id => type_term_id
                  )
                  rank+=1
                }      
                # qualifiers
                qual_rank.clear
                feature.qualifiers.each do |qualifier|
                  qual_term_id = anno_tag_terms["#{qualifier.qualifier}"] || (anno_tag_terms["#{qualifier.qualifier}"] = Term.find_or_create_by_name_and_ontology_id(qualifier.qualifier, Term.ano_tag_ont_id).id)
                  qual_rank["#{qualifier.qualifier}"]||=0
                  qual_rank["#{qualifier.qualifier}"]+=1
                  base.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id, term_id,value,rank)
                  VALUES(#{new_seqfeature_id},#{qual_term_id},'#{qualifier.value.to_s[0,3999].gsub(/\'/,"''")}',#{qual_rank["#{qualifier.qualifier}"]})")
                end
                printf("\t... #{feature_count}/#{entry.features.size} done\n") if (verbose && feature_count%1000==0)
                feature = nil
              end#End bioentry Features
              printf("\t... #{feature_count}/#{entry.features.size} done\n") if verbose
            end            
          else#Found exisiting bioentry
            puts "Skipping Existing : #{entry.accession} (#{entry.length}) - #{entry.definition} - version:#{bioentry.version} features:#{bioentry.seqfeatures.count} references:#{bioentry.bioentry_references.count}" if verbose
            bad_count+=1
          end#End this bioentry
          entry = nil
        end#End Bioentry loop
      end#End Transaction
    rescue  => e
      puts "\n***** There was an error loading entry #{entry_count}. *****\n#{$!}#{verbose ? e.backtrace.join("\n") : ""}"
      bad_count +=1
    end
    # report entry count
    total_count = entry_count - bad_count
    if ( total_count == 0)
      puts "No valid entries in file!"
      exit 0
    else
      # convert the time taken and output
      fin_time = Time.now
      time_taken = fin_time - curr_time
      days = (time_taken / 86400).floor
      remainder = time_taken % (24*60*60)
      puts "\t... loaded #{total_count} #{(total_count > 1) ? "entries" : "entry"} in #{(days > 0) ? "#{days} days" : ''} #{Time.at(remainder).gmtime.strftime('%R:%S')}"
    end    
    # Sync the database with new sequence and features
    bio_db.sync_database
    # Done
    task_end_time = Time.now
    puts "Finished - #{Time.now.strftime('%m/%d/%Y - %H:%M:%S')} :: #{Time.at(task_end_time - task_start_time).gmtime.strftime('%R:%S')}"
  end
  
  protected
  # parse the entry and find an acession based on the file type, raise an error if none can be found. All bioentries need an accession
  def get_entry_accession(entry,file_type)
    if(entry.accession && !entry.accession.blank?)
      entry_accession = entry.accession
    else
      case file_type
      when 'fasta'
        entry_accession = entry.entry_id
        if(entry.locus)
          entry_accession << '.' << entry.locus
        end
      when 'genbank'
        entry_accession = entry.locus.entry_id
      end
    end
    raise "Accession error: Could not infer entry accession:#{entry.get("LOCUS")}" if entry_accession.blank?
    return entry_accession
  end
  # compare the entry against taxon in the database. Try to find an existing match. Create a new taxonomy if none found
  def get_entry_taxonomy(entry,opts={})
    # setup user supplied species
    species_taxon = nil
    if(opts[:species])
      species_taxon = (t = TaxonName.find_by_name(opts[:species])) ? t.taxon : create_taxon(opts[:species])
    elsif(opts[:species_id])
      species_taxon = TaxonName.find(opts[:species_id]).taxon
    end
    # setup user supplied strain/variety
    strain_taxon = nil
    if(opts[:strain])
      strain_taxon = (t = TaxonName.find_by_name(opts[:strain])) ? t.taxon : create_taxon(opts[:strain],'varietas')
    elsif(opts[:strain_id])
      strain_taxon = TaxonName.find(opts[:strain_id]).taxon
    else
    # strain not supplied - look for organism
    if(entry.respond_to?(:organism))
      if(tn = TaxonName.find_by_name(entry.organism) )
        strain_taxon = tn.taxon
      else
        t = nil
        entry.source_features.find do |source|
          unless (results = source.qualifiers.select{|q| q.qualifier=='db_xref' && q.value.match(/taxon/)}.collect{|q| Taxon.find_by_ncbi_taxon_id(q.value.match(/taxon:(\d+)/)[1])}).empty?
            t = results.first
            true
          end
          false
        end
        strain_taxon = t
      end
    end
    end
    # species not supplied
    if species_taxon.nil?
      # strain supplied - If the strain/varietas is above species rank, the taxonomy will be 'unknown'
      if strain_taxon
        species_taxon = strain_taxon.species || Taxon.unknown
      # species and strain not set ...
      else
        raise "Could not infer taxonomy for: #{entry.accession}.You must supply strain_name= and/or species_name=. If unknown use: --species_name='Unidentified'"
      end
    # species supplied - check strain
    else
      strain_taxon ||= species_taxon
    end
    # check for ancestry
    unless species_taxon.parent_taxon_id
      species_taxon.update_attribute(:parent_taxon_id,Taxon.root.taxon_id)
    end
    unless strain_taxon.parent_taxon_id
      strain_taxon.update_attribute(:parent_taxon_id,species_taxon.taxon_id)
    end
    return species_taxon,strain_taxon
  end
  
  def create_taxon(taxon_name, node_rank='species')
    puts "No taxon found for #{taxon_name} - Creating new entry."
    begin
      # try to create so we can continue
      unless (Taxon.count > 0)
        response = "*** The taxonomy tree is empty. You should load it before running this script with - 'thor taxonomy:load'  Type 'yes' to continue:"
        unless response == 'yes'
          exit 0
        end
      end
      taxon = Taxon.create(:node_rank  => node_rank, :genetic_code => '1', :mito_genetic_code  => '1', :non_ncbi => 1)
      taxon.taxon_names.create(:name => taxon_name, :name_class => "scientific name")
    rescue
      puts "Error creating taxon\n#{$!}"
    end
    return taxon
  end
end