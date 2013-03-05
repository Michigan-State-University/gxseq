class Sequence < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  
  desc 'load FILE','Load genomic sequence into the database'
  method_options :verbose => false, :show_percent => false, :version => "1", :source_name => "EMBL/GenBank/SwissProt"
  method_options :transcriptome => false
  method_option :add_entry_feature, :desc => 'Add a feature of the supplied type to every entry from beginning to end of the sequence. Useful for adding mRNA or CDS to transcriptome fasta data'
  method_option :strain
  method_option :strain_id
  method_option :species_id
  method_option :division
  method_option :molecule_type
  method_option :renumber_contigs, :type => :string, :desc => "Renumber each contig with the supplied prefix. Outputs genome.concordance"
  method_option :database, :default => 'Public', :desc  => "Name of Biodatabase to use. Not used by app"
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
    prefix = options[:renumber_contigs]
    show_percent = options[:show_percent]
    entry_count = 0
    type_names = []
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
    # Open the concordance if we need it
    concordance_file = File.open(input_file+'.concordance','w') if prefix
    # Setup namespace and source term
    bio_db = Biodatabase.find_or_create_by_name(database)
    seq_src_term = Term.find_or_create_by_name_and_ontology_id(source_name,Term.seq_src_ont_id)
    # Turn off versioning before mass load. We don't store the creates from scripted loaders
    PaperTrail.enabled = false
    # Put this all in a transaction, just in case. We don't want partial bioentries
    begin
      Biodatabase.transaction do
        # Setup taxon version and taxon ids just once for a transcriptome to speed up the load -  allows only one species per load
        if(is_transcriptome)
          species_taxon, strain_taxon = get_entry_taxonomy(data.entries.first,{:strain => strain,:species_id => species_id,:strain_id => strain_id})
          assembly = Transcriptome.find_or_create_by_version_and_species_id_and_taxon_id(version,species_taxon.id,strain_taxon.id)
          # link Biodatabase
          bio_db.taxons << species_taxon unless bio_db.taxons.include?(species_taxon)
        end
        # Setup the entry_feature term id once and grab the locus term id
        if(entry_feature)
          entry_feature_type_term_id = Term.find_or_create_by_name_and_ontology_id(entry_feature,Term.seq_key_ont_id).id
          locus_term_id = Term.find_or_create_by_name_and_ontology_id('locus_tag', Term.ano_tag_ont_id).id
        end
        # Reset the IO stream
        data.rewind
        # Save the count for reporting
        if(show_percent)
          progress_bar = ProgressBar.new(data.entries.size)
        end
        # Reset the IO stream again
        data.rewind
        # Loop through each of the entries we receive from FlatFile iterator
        data.each do |entry|
          # Getting an empty entry at end of file so we check blank entries       
          next if(entry.accession.blank? && entry.definition.blank? && entry.seq.length == 0 && entry.features.size == 0)
          #update the counter
          entry_count +=1
          #create the accesion for this sequence based on accession, entry_id, and locus          
          entry_accession = get_entry_accession(entry,file_type)
          # Renumber the accession and store concordance
          if(prefix)
            new_accession = (sprintf "%s%06d", prefix, entry_count)
            concordance_file.write("#{entry_accession}\t#{new_accession}")
            entry_accession = new_accession
          end
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

          # Get Taxon Version - Genomes lookup for each entry
          unless(is_transcriptome)
            species_taxon, strain_taxon = get_entry_taxonomy(entry,{:strain => strain,:species_id => species_id,:strain_id => strain_id})
            # Get version
            assembly = Genome.find_or_create_by_version_and_species_id_and_taxon_id(version,species_taxon.id,strain_taxon.id)
            # link Biodatabase
            bio_db.taxons << species_taxon unless bio_db.taxons.include?(species_taxon)
          end

          
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
            puts "\tDNA -\tGenomic DNA: Sequence derived directly from the DNA\n\t\tof an organism. Note: The DNA sequence of an rRNA gene has this\n\t\tmolecule type, as does that from a naturally-occurring plasmid."
            puts "\tRNA -\tGenomic RNA: Sequence derived directly from the genomic\n\t\tRNA of certain organisms, such as viruses."
            puts "\tpRNA -\tPrecursor RNA: An RNA transcript before it is processed\n\t\tinto mRNA, rRNA, tRNA, or other cellular RNA species."
            puts "\tmRNA -\tmRNA[cDNA]: A cDNA sequence derived from mRNA."
            puts "\trRNA -\tRibosomal RNA: A sequence derived from the RNA in ribosomes.\n\t\tThis should only be selected if the RNA itself was isolated\n\t\tand sequenced. If the gene for the ribosomal RNA was\n\t\tsequenced, select Genomic DNA."
            puts "\ttRNA -\tTransfer RNA: A sequence derived from the RNA in a\n\t\ttransfer RNA, for example, the sequence of a cDNA derived from tRNA."
            puts "\tother -\tOther-Genetic: A synthetically derived sequence including\n\t\tcloning vectors and tagged fusion constructs."
            puts "\tcRNA -\tA sequence derived from complementary RNA transcribed\n\t\tfrom DNA, mainly used for viral submissions."
            puts "\ttransRNA -A sequence derived from any transcribed RNA not listed above."
            puts "\ttmRNA -\tTranfer-messenger RNA: A sequence derived from transfer\n\t\tmessenger RNA, which acts as a tRNA first and then an mRNA\n\t\tthat encodes a peptide tag. If the gene for the tmRNA was\n\t\tsequenced, use genomic DNA."
            puts "\tncRNA -\tncRNA: A sequence derived from other non-coding RNA not specified"
            raise "*** No molecule type found\n"
          end
          
          # Check for existing entry
          #testing for existence slows down transcriptome load
          #just allow it to die if Bioentry already exists
          #unless(bioentry = Bioentry.find_by_assembly_id_and_biodatabase_id_and_accession_and_version(assembly.id,bio_db.id,entry_accession,entry_version))
            # bioentry
            # use fast_insert to skip model creation and validation and speed up load... at the cost of orm access
            #bioentry = bio_db.bioentries.new(
            bioentry_id = Bioentry.fast_insert(
            :assembly_id => assembly.id,
            :taxon_id  => assembly.taxon_id,
            :name => entry_accession,
            :accession => entry_accession,
            :identifier => 0,
            :division => entry_division,
            :description => entry.definition,
            :version => entry_version
            )
            # biosequence
            bioseq = Biosequence.fast_insert(
            :version => entry_version,
            :length => entry_bioseq.length,
            :alphabet => alphabet,
            :seq  => entry.seq.upcase,
            :bioentry_id => bioentry_id
            )
            # entry and bioseq are built and then saved to allow indexer lookup of bioseq in callback
            # 
            #bioentry.save!
            
            # use our own internal id for bioentry->identifier
            #** Skip this. It can be done in BioDB->sync but we don't use identifier anyway
            #bioentry.update_attribute(:identifier, bioentry.id)
            
            # New Entry Feature?
            if(entry_feature)
              new_seqfeature_id=Seqfeature.fast_insert(
                :bioentry_id => bioentry_id,
                :type_term_id => entry_feature_type_term_id,
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
                :term_id => entry_feature_type_term_id
              )
              base.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
              VALUES(#{new_seqfeature_id},#{locus_term_id},'#{entry_accession}',1)")
            end
            # comment(s)
            if(entry_bioseq.comments.kind_of?(Array) && !entry_bioseq.comments.empty?)
              comment_rank=0
              entry_bioseq.comments.each do |c|
                comment_rank+=1
                Comments.fast_insert(
                :comment_text => c,
                :rank  => comment_rank
                )
              end
            elsif(entry_bioseq.comments.kind_of?(String) && !entry_bioseq.comments.empty?)
              Comments.fast_insert(
              :comment_text => entry_bioseq.comments,
              :rank => 0
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
              base.connection.execute("INSERT INTO bioentry_dbxref(bioentry_id,dbxref_id,rank) VALUES(#{bioentry_id},#{new_xref.id},#{b_dbx_rank})")        
              b_dbx_rank+=1
            end

            # references
            if(entry.respond_to?(:references))
              entry_reference_count = 0
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
                entry_reference_count +=1
                # link reference to bioentry
                BioentryReferences.fast_insert(
                :reference_id => new_reference.id,
                :start_pos => reference.sequence_position ? reference.sequence_position.split('-')[0] : 0,
                :end_pos => reference.sequence_position ? reference.sequence_position.split('-')[1] : entry_bioseq.length,                
                :rank => entry_reference_count
                )
              end
            end
            if(entry.respond_to?( :keywords ))
              # Bioentry Qualifier Values
              ## keywords
              rank = 1
              entry.keywords.each do |keyword|
                key_term = Term.find_or_create_by_name_and_ontology_id("keyword", Term.ano_tag_ont_id)
                BioentryQualifierValues.fast_insert(
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
                BioentryQualifierValues.fast_insert(
                :term_id => acc_term.id,
                :value => accession,
                :rank => rank)
                rank +=1
              end
            end
            
            if(entry.respond_to?(:date))
              ## date
              unless(entry.date.nil? || entry.date.empty?)
                BioentryQualifierValues.fast_insert(
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
                # store the type name
                type_name = feature.feature.downcase.camelize.gsub(/\W/,"").gsub(/_+/,"")
                type_names.push(type_name).uniq!
                # seqfeature
                new_seqfeature_id=Seqfeature.fast_insert(
                :bioentry_id => bioentry_id,
                :type_term_id => type_term_id,
                :source_term_id => seq_src_term.id,
                :rank => feat_rank["#{feature.feature}"],
                :display_name => type_name
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
          # NOTE: Not testing for existing bioentry anymore. Just letting the transaction fail
          # else#Found exisiting bioentry
          #   puts "Skipping Existing : #{entry.accession} (#{entry.length}) - #{entry.definition} - version:#{bioentry.version} features:#{bioentry.seqfeatures.count} references:#{bioentry.bioentry_references.count}" if verbose
          #   bad_count+=1
          # end#End this bioentry
          entry = nil
          if show_percent
            progress_bar.increment!
          end
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
    # Turn on versioning before sync
    PaperTrail.enabled = true
    # Sync the database with new sequence and features
    bio_db.sync_database
    # Done
    task_end_time = Time.now
    puts "Finished - #{Time.now.strftime('%m/%d/%Y - %H:%M:%S')} :: #{Time.at(task_end_time - task_start_time).gmtime.strftime('%R:%S')}"
    puts "Checking Feature Types"
    check_feature_types(type_names)
  end
  
  protected
  # Compare the types we loaded to the Classes that exist in the app
  def check_feature_types(type_names)
    type_names.each do |name|
      begin
        Object.const_get name
      rescue
        puts " -- #{name} not found"
        puts "class #{name} < Seqfeature; end;"
      end
    end
  end
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
    if(opts[:species_id])
      species_taxon = Taxon.find(opts[:species_id])
    end
    # setup user supplied strain/variety
    strain_taxon = nil
    if(opts[:strain])
      strain_taxon = (TaxonName.find_by_name(opts[:strain]) || create_taxon(opts[:strain],'varietas')).try(:taxon) 
    elsif(opts[:strain_id])
      strain_taxon = TaxonName.find(opts[:strain_id]).taxon
    end
    
    # look at organism
    if(entry.respond_to?(:organism))
      if(tn = TaxonName.find_by_name(entry.organism) )
        org_taxon = tn.taxon
      else
        t = nil
        entry.source_features.find do |source|
          unless (results = source.qualifiers.select{|q| q.qualifier=='db_xref' && q.value.match(/taxon/)}.collect{|q| Taxon.find_by_ncbi_taxon_id(q.value.match(/taxon:(\d+)/)[1])}).empty?
            t = results.first
            true
          end
          false
        end
        org_taxon = t
      end
    end

    # species not supplied
    if species_taxon.nil?
      species_taxon = strain_taxon.try(:species) || org_taxon || Taxon.unknown
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
    puts "No taxon found for #{taxon_name} - Do you want to create a new entry? (This is not advised. Use taxonomy:load and taxonomy:find to get the correct taxon) (Y or N):"
    unless(STDIN.gets.chomp=='Y')
      raise 'No Taxon Available - Try taxonomy:load or taxonomy:find'
    end
    begin
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
