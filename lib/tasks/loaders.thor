
class Db < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  require 'net/ftp'
  require 'zlib'
  # TODO : remove all Bio::SQL reference
  desc 'load_seq FILE','Load genomic sequence into the database'
  method_options :namespace => 'private', :verbose => false
  method_option :version
  method_option :taxon_name
  method_option :division
  method_option :molecule_type
  def load_seq(input_file)
     # setup
    revision = options[:version]
    namespace = options[:namespace]
    verbose = options[:verbose]
    taxon_name = options[:taxon_name]
    division = options[:division]
    molecule_type = options[:molecule_type]
    entry_count = 0
    seq_key_terms = {}
    anno_tag_terms = {}
    qual_rank = {}
    feat_rank = {}
    bad_count = 0
    base = ActiveRecord::Base
    task_start_time = Time.now
    
    # Parse input
    begin
      data = Bio::FlatFile.open(input_file,"r")
    rescue
      puts "*** Error parsing input *** \n#{$!}"
      exit 0
    end

    # grab the time for stats
    curr_time = Time.now

    # First setup our namespace
    bio_db = Biodatabase.find_or_create_by_name(namespace)

    # default ontology/term setup 
    seq_src_ont_id = Ontology.find_or_create_by_name("SeqFeature Sources").id
    seq_key_ont_id = Ontology.find_or_create_by_name("SeqFeature Keys").id
    ano_tag_ont_id = Ontology.find_or_create_by_name("Annotation Tags").id
    seq_src_term = Term.find_or_create_by_name_and_ontology_id("EMBL/GenBank/SwissProt",seq_src_ont_id)


    # Loop through each of the entries we receive (From file or STDIN)
    data.each do |e|
      #clone the iterator, allow for garbage collection
      entry = e.clone
      # Put this all in a transaction, just in case. We don't want partial bioentries
      begin
        Biodatabase.transaction do
          # Getting an empty entry at end of file so we skip it here          
          next if(entry.accession.blank? && entry.definition.blank? && entry.seq.length == 0 && entry.features.size == 0)
          
          #create the accesion for this sequence based on acc, entry_id and locus
          entry_accession = nil
          if(entry.accession)
            entry_accession = entry.accession
          else
            if(entry.entry_id)
              entry_accession = entry.entry_id
            end
            if(entry.locus)
              entry_accession << '.' << entry.locus
            end
          end
          raise "Accession error: Could not infer entry accession:" unless entry_accession
          
          entry_count +=1
          entry_bioseq = entry.to_biosequence
          puts "Working on entry #{entry_count}: #{(entry.definition.length > 75) ? entry.definition.length[0,74]+"..." : entry.definition}" if verbose

          # Get Entry version
          if(entry.respond_to?(:version))
            entry_version = revision.nil? ? (entry.version.nil? ? 1 : entry.version) : revision
            if revision && verbose
              puts "using entry_version: #{entry_version}" 
            elsif verbose
              puts "using version from file: #{entry_version}"
            end
          else
            entry_version = revision || 1
          end
          
          # Get Entry taxonomy
          taxon=nil
          if(taxon_name)
            if(tn = TaxonName.find_by_name(taxon_name) )
              taxon = tn.taxon
            end
          elsif(entry.respond_to?(:organism))
            taxon_name = entry.organism
            if(tn = TaxonName.find_by_name(taxon_name) )
              taxon = tn.taxon
            elsif(entry.features.first.feature=='source' && (source_taxon_match = entry.features.first.qualifiers.collect{|q| (q.qualifier=='db_xref' && (m = q.value.match(/taxon:(\d+)/))) ? m : nil}.compact).any?  && ( t = Taxon.find_by_ncbi_taxon_id(source_taxon_match.first[1]) ))
              taxon = t
            end
          else
            raise "Could not infer taxonomy for: #{entry.accession}.You must supply taxon_name="
          end
          if(!taxon)
            puts "No taxon found for #{taxon_name} - Creating new entry"
            begin
              # try to create so we can continue
              unless (Taxon.count > 0)
                puts "*** The taxonomy tree is empty. You should load it before running this script.***"
                parent = Taxon.create(:node_rank  => "species", :genetic_code => '1', :mito_genetic_code  => '0')
                parent.taxon_names.create(:name => taxon_name, :name_class => "scientific name") 
              else
                # We should probably loop through the taxonomy tree creating taxon and looking for a match we can attach to
                #   entry.taxonomy.chop.split("; ").each do |name|
                #   end
                # For now just make the new taxon
                parent = Taxon.create(:node_rank  => "species", :genetic_code => '1', :mito_genetic_code  => '0')
                parent.taxon_names.create(:name => taxon_name, :name_class => "scientific name")
              end
              taxon = parent
            rescue
              raise "Error creating taxon\n#{$!}"
            end
          end
          
          # Get Taxon Version
          taxon_version = TaxonVersion.find_or_create_by_version_and_taxon_id(entry_version, taxon.id)
          taxon_version.species_id ||= taxon.species.id
          taxon_version.name ||= taxon.name
          taxon_version.save!
          
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
            raise "*** No division could be found"
          end
          
          # Check for existing entry
          unless(bioentry = Bioentry.find_by_biodatabase_id_and_accession_and_version(bio_db.id,entry_accession,entry_version))
            # bioentry
            bioentry = bio_db.bioentries.create(
            :taxon_version => taxon_version,
            :name => entry_accession,
            :accession => entry_accession,
            :identifier => 0,
            :division => entry_division,
            :description => entry.definition,
            :version => entry_version
            )
            bioentry.update_attribute(:identifier, bioentry.id) #use our own internal id for bioentry->identifier
            
            # biosequence
            bioseq = bioentry.create_biosequence(
            :version => entry_version,
            :length => entry.length,
            :alphabet => entry_bioseq.molecule_type || (molecule_type || (raise "A molecule type could not be found. Please supply molecule_type=")),
            :seq  => entry.seq.upcase
            )

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
              #be_xref = Bio::SQL::BioentryDbxref.create(:bioentry_id => bioentry.id, :dbxref_id => new_xref.id, :rank => b_dbx_rank) 
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
                :start_pos => reference.sequence_position.split('-')[0],
                :end_pos => reference.sequence_position.split('-')[1],
                :rank => bioentry.bioentry_references.size + 1
                )
              end
            end
            if(entry.respond_to?( :keywords ))
              # Bioentry Qualifier Values
              ## keywords
              rank = 1
              entry.keywords.each do |keyword|
                key_term = Term.find_or_create_by_name_and_ontology_id("keyword", ano_tag_ont_id)
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
                acc_term = Term.find_or_create_by_name_and_ontology_id("secondary_accession", ano_tag_ont_id)
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
                :term_id => Term.find_or_create_by_name_and_ontology_id("date_modified", ano_tag_ont_id).id,
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
                type_term_id=seq_key_terms["#{feature.feature}"] || (seq_key_terms["#{feature.feature}"] = Term.find_or_create_by_name_and_ontology_id(feature.feature,seq_key_ont_id).id)      
                feat_rank["#{feature.feature}"]||=0
                feat_rank["#{feature.feature}"]+=1
                # seqfeature
                new_seqfeature_id=Seqfeature.fast_insert(
                :bioentry_id => bioentry.id,
                :type_term_id => type_term_id,
                :source_term_id => seq_src_term.id,
                :rank => feat_rank["#{feature.feature}"]
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
                  :rank => rank)
                  rank+=1
                }      
                # qualifiers
                qual_rank.clear
                feature.qualifiers.each do |qualifier|
                  qual_term_id = anno_tag_terms["#{qualifier.qualifier}"] || (anno_tag_terms["#{qualifier.qualifier}"] = Term.find_or_create_by_name_and_ontology_id(qualifier.qualifier, ano_tag_ont_id).id)
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
        end#End Transaction
      rescue  => e
        puts "\n***** There was an error loading entry #{entry_count}. *****\n#{$!}#{verbose ? e.backtrace.inspect : ""}"
        bad_count +=1
        exit 0
      end
      entry = nil
    end#End Bioentry loop

    total_count = entry_count - bad_count

    if ( total_count == 0)
      puts "No valid entries in file!"
    else
      # convert the time taken and output
      fin_time = Time.now
      time_taken = fin_time - curr_time
      days = (time_taken / 86400).floor
      remainder = time_taken % (24*60*60)
      puts "\t... loaded #{total_count} #{(total_count > 1) ? "entries" : "entry"} in #{(days > 0) ? "#{days} days" : ''} #{Time.at(remainder).gmtime.strftime('%R:%S')}"
      puts "\t... Done"
    end
    
    begin
      # update the sti column
      Term.denormalize
    rescue
      puts $!
    end
    
    begin    
      # update track information
      Bioentry.all.each do |b|
        b.create_tracks
      end
    rescue
      puts $!
    end
    
    begin
      # setup the gene models
      GeneModel.generate
    rescue
      puts $!
    end
    
    begin
      # setup the GC Content Big_Wig Files
      puts "Building GC_content files - #{Time.now.strftime('%m/%d/%Y - %H:%M:%S')}"
      Bioentry.all.each do |b|
        b.biosequence.generate_gc_data
      end 
    rescue
      puts $!
    end
         
    # Done
    task_end_time = Time.now
    puts "Finished - #{Time.now.strftime('%m/%d/%Y - %H:%M:%S')} :: #{Time.at(task_end_time - task_start_time).gmtime.strftime('%R:%S')}"
  end
  
  desc 'load_taxon',"Load ncbi taxonomy data into the database"
  method_options :directory => "lib/data/taxdata/",:download => false, :verbose => false, :nested_only => false
  def load_taxon
    download = options[:download]
    nested_set_only = options[:nested_only]
    verbose = options[:verbose]
    tax_directory = options[:directory]
    base = ActiveRecord::Base
    start_time = Time.now
    
    puts "-v supplied, using verbose output" if verbose
    puts "Loading NCBI Taxonomy"
    if(download)
      # Downloading New taxonomy data
      puts "\t... Downloading taxonomy data" if verbose
      ftp = Net::FTP.new('ftp.ncbi.nlm.nih.gov')
      ftp.login
      ftp.chdir('/pub/taxonomy')
      ftp.getbinaryfile('taxdump.tar.gz',"#{tax_directory}taxdump.tar.gz")
      ftp.close
      puts "\t\t... extracting data" if verbose
      `gunzip -f #{tax_directory}taxdump.tar.gz`
      `cd #{tax_directory}; tar -xf taxdump.tar; rm -f taxdump.tar`
    end
    
    unless(nested_set_only)
      
      # Start the work
      puts "\t... retrieving all taxon nodes in the database\n" if verbose
      old_nodes = base.connection.select_all("SELECT taxon_id, ncbi_taxon_id, parent_taxon_id, node_rank, genetic_code, mito_genetic_code
                                     FROM taxon ORDER BY ncbi_taxon_id")
    
      # try to minimize the parent updates by mapping NCBI
      # taxonIDs to primary keys for the nodes we already have
      id_to_ncbi_map = {}
      ncbi_to_db_id_map = {}
      ncbi_to_data_map = {}
      ncbi_to_parent_ncbi = {}
      old_nodes.each do |node|
       id_to_ncbi_map[node['taxon_id']]=node['ncbi_taxon_id']
      end
      old_nodes.each do |node|
       ncbi_to_data_map[node['ncbi_taxon_id']]=[node['ncbi_taxon_id'].to_s,id_to_ncbi_map[node['parent_taxon_id']].to_s,node['node_rank'],node['genetic_code'].to_s,node['mito_genetic_code'].to_s]
      end                                
      old_nodes = nil
      new_nodes = []
      update_nodes = []
      # compare the nodes to our database values, store those needing work
      puts "\t... reading in taxon nodes from nodes.dmp\n" if verbose
      old_node_count = 0
      File.open(tax_directory+'nodes.dmp',"r"){|file|
       file.each do |line|
         data = line.split(/\s*\|\s*/)
         # tax_id, parent_tax_id, rank, genetic_code, mito_genetic_code
         a = [data[0],data[1],data[2],data[6],data[8]]
         #skip if the file data is invalid
         next if a.compact.size < 5
         # if we have the ncbi_id_stored
         if(old = ncbi_to_data_map[a[0]])      
           # if our data and the ncbi data matches
           if (ncbi_to_data_map[a[0]] == a)
             # no update necessary
             old_node_count +=1
           else
             # needs update
             update_nodes << a
             ncbi_to_parent_ncbi[a[0]]=a[1]
           end      
           # done with this data remove from hash
           ncbi_to_data_map.delete(a[0])
         else
           # new ncbi_id
           new_nodes << a
           ncbi_to_parent_ncbi[a[0]]=a[1]
         end
       end
      }
      puts "\t\tnew: #{new_nodes.size}, update: #{update_nodes.size}, delete: #{ncbi_to_data_map.size}, keep: #{old_node_count}" if verbose

      # Insert / Update / Delete nodes
      begin
      Taxon.transaction do
       # insert first ...
       db_time = Time.now.to_s(:db)
       tot = new_nodes.length
       time = Time.now
       last_i = 0
       puts "\t... insert taxon nodes\n" if verbose && tot > 0
       new_nodes.each_with_index do |new_node, i|
         Taxon.fast_insert(
          :ncbi_taxon_id => new_node[0],
          :node_rank => new_node[2],
          :genetic_code => new_node[3],
          :mito_genetic_code => new_node[4])  
          if (verbose && a = log_work(i,last_i,time,tot));(last_i, time = a);end
       end

       # .. update ..
       tot = update_nodes.length
       time = Time.now
       last_i = 0
       puts "\t... update taxon nodes\n" if verbose && tot > 0
       update_nodes.each_with_index do |update_node, i|
         base.connection.execute("UPDATE Taxon 
           SET node_rank='#{update_node[2]}',genetic_code=#{update_node[3]},mito_genetic_code=#{update_node[4]}
           WHERE ncbi_taxon_id=#{update_node[0]}")
         if (verbose && a = log_work(i,last_i,time,tot,2000));(last_i, time = a);end
       end

       # .. get new primary ids ..
       puts "\t... selecting new parent IDs\n" if verbose
       all_nodes = base.connection.select_all("SELECT taxon_id, ncbi_taxon_id
                                               FROM taxon ORDER BY ncbi_taxon_id")
       all_nodes.each do |node|
         ncbi_to_db_id_map[node['ncbi_taxon_id'].to_s]=node['taxon_id']
       end
       all_nodes = nil

       # ... then update parent_ids
       tot = ncbi_to_parent_ncbi.length
       time = Time.now
       last_i = 0
       puts "\t... updating parent IDs\n" if verbose and tot > 0
       ncbi_to_parent_ncbi.each_with_index do |(ncbi_id,ncbi_parent_id),i|
         base.connection.execute("UPDATE Taxon
         SET parent_taxon_id = #{ncbi_to_db_id_map[ncbi_parent_id.to_s]}
         WHERE ncbi_taxon_id = #{ncbi_id}")
         if (verbose && a = log_work(i,last_i,time,tot));(last_i, time = a);end
       end

      end
      rescue
       puts "**Error with Taxon:\n\t#{$!}"
       #exit 0
      end

      # free up some memory
      id_to_ncbi_map = nil
      ncbi_to_data_map = nil
      ncbi_to_parent_ncbi = nil
      update_nodes = nil
      new_nodes = nil
      GC.start

      # Taxon Names
      begin
      Bio::SQL::TaxonName.transaction do

       puts "\t... reading in taxon names from names.dmp\n" if verbose
       taxon_names_file = File.open(tax_directory+'names.dmp',"r")

       # delete all names for taxon nodes with a NCBI taxonID
       puts "\t... deleting old taxon names\n" if verbose
       base.connection.execute("DELETE FROM TAXON_NAME WHERE taxon_id in (SELECT taxon_id FROM taxon t WHERE t.ncbi_taxon_id IS NOT NULL)")

       # now add the new taxon names from the download
       puts "\t... inserting new taxon names\n" if verbose
       tot = `wc -l #{tax_directory+'names.dmp'}`.split.first.to_i
       time = Time.now
       last_i = 0
       i = 0
       taxon_names_file.each do |line|
         data = line.split(/\s*\|\s*/)
         base.connection.execute("INSERT INTO TAXON_NAME (taxon_id, name, name_class) VALUES (#{ncbi_to_db_id_map[data[0].to_s]}, '#{data[1].gsub(/\'/,"''")}', '#{data[3].gsub(/\'/,"''")}')")
         if (verbose && a = log_work(i,last_i,time,tot,100000));(last_i, time = a);end
         i+=1
       end
       taxon_names_file.close
      end
      rescue
       puts "**Error with Taxon Name:\n\t#{$!}"
       exit 0
      end                         
    end#nested_set_only test
  
    # Rebuilding the Nested Set Tree - using globals for recursive functions - not very clean. Needs refactor to OO class
    @@nested_count = 0
    @@conn = base.connection
    @@taxon_tot = Bio::SQL::Taxon.count
    @@taxon_count = 0
    @@last_taxon_count=0
    @@time = 0
    @@v = verbose
    @@parent_child_map = Hash.new()
    @@time = Time.now

    base.connection.select_all("SELECT taxon_id, parent_taxon_id FROM taxon ORDER BY ncbi_taxon_id").each do |node|
      @@parent_child_map[node["parent_taxon_id"].to_i] ||= [] 
      (@@parent_child_map[node["parent_taxon_id"].to_i] << node["taxon_id"].to_i) unless (node["parent_taxon_id"].to_i == node["taxon_id"].to_i) # skip if node points at self
    end
    

    
    # Nested set calculation
    begin
      puts "\t... rebuilding nested set left/right values\n" if verbose

      # Clear out the current left and right values
      # Can't wrap DDL in Transaction  
      printf "\t\t clearing left values\n" if verbose
      begin
        @@conn.remove_column(:taxon,:left_value)
      rescue
        puts "taxon->left_value column missing o_O why?"
        # it didn't exist?
      end
      @@conn.add_column(:taxon,:left_value,:integer)

      printf "\t\t clearing right values\n" if verbose
      begin
      @@conn.remove_column(:taxon,:right_value)
      rescue
        puts "taxon->right_value column missing o_O why?"
        # it didn't exist?
      end
      @@conn.add_column(:taxon,:right_value,:integer)
      printf "\t\t ..rebuilding\n"

      Bio::SQL::Taxon.transaction do
        root_id=(Bio::SQL::TaxonName.find_by_name('root') || Taxon.find(:first, :conditions => "parent_taxon_id == taxon_id OR parent_taxon_id is null")).taxon_id
        update_nested_set(root_id.to_i)
      end
    rescue
      puts "**Error with Nested set:\n\t#{$!}"
      exit 0
    end

    output_time(start_time) 
  end # end load_taxon task
  
  protected
  
  # tell thor to ignore these methods
    def update_nested_set(current_id)
      @@taxon_count+=1
      @@nested_count+=1  
      @@conn.execute("Update Taxon SET left_value = #{@@nested_count} where taxon_id = #{current_id}")
      (@@parent_child_map[current_id] || []).each do |child_id|
        update_nested_set(child_id.to_i)
      end  
      @@nested_count+=1
      @@conn.execute("Update Taxon SET right_value = #{@@nested_count} where taxon_id = #{current_id}")
      if (@@v && a = log_work(@@taxon_count,@@last_taxon_count,@@time,@@taxon_tot));(@@last_taxon_count, @@time = a);end
    end
  
    ## OUTPUT HELPER FUNCTIONS 
    # output log data
    def log_work(i,last_i, time, tot, chunk=50000)
      idx = i+1
      if(idx - chunk >= last_i || idx == tot )
        elapsed = (Time.now-time)
        printf("\t\t%d/%d done (in %d secs, %4.1f rows/s)\n", idx,tot,elapsed,(idx-last_i)/elapsed)
        return last_i+chunk, Time.now
      else
        return false
      end
    end

    # convert the time taken and output
    def output_time(start_time)
      time_taken = Time.now - start_time
      days = (time_taken / 86400).floor
      remainder = time_taken % (24*60*60)
      puts "Done  ... in #{(days > 0) ? "#{days} days" : ''} #{Time.at(remainder).gmtime.strftime('%R:%S')}"
    end
  
end


