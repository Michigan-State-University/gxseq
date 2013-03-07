class Blast < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')

  desc "create_run FILE", 'load xml formatted blast results into the database'
  method_options %w(database -d) => :required,
    %w(assembly_id -t) => :required,
    %w(remove_splice -r) => false,
    %w(use_search_index -u) => false,
    %w(feature_type -f) => 'Gene', %w(concordance -c) => nil,
    :test => false
  def create_run(input_file)
    # Parse input
    begin
      open_blast = File.open(input_file,'r')
      blast_file = Bio::Blast::Report.xmlparser(open_blast)
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    # verify database
    blast_db = BlastDatabase.find_by_name(options[:database]) || BlastDatabase.find_by_id(options[:database])
    unless blast_db
      puts "Could not find blast database with name: #{blast_db}"
      exit 0
    end
    # verify taxon
    assembly = Assembly.find_by_id(options[:assembly_id])
    unless assembly
      puts "Could not find assembly with id:#{options[:assembly_id]}"
      exit 0
    end
    # verify type if provided
    if(options[:feature_type])
      unless type_term = Term.where{(upper(name)==my{options[:feature_type].upcase}) & (ontology_id == Term.seq_key_ont_id)}.first
        puts "Could not find term: #{options[:feature_type]}"
        exit 0
      end
      type_term_id = type_term.id
    end
    # Check and parse concordance
    concordance_hash={}
    if(options[:concordance])
      begin
        concordance_file = File.open(options[:concordance],"r")
        concordance_file.each do |line|
          file_id,locus_tag = line.chomp.split("\t")
          concordance_hash[file_id]=locus_tag
        end
      rescue
        puts "*** Error opening concordance *** \n#{$!}"
        exit 0
      end
    end
    # Count iterations
    puts "Counting iterations"
    count = 0
    total = 0
    blast_file.reports.each do |report|
      total +=1 
      count +=1 if report.hits.length > 0
    end
    unless(no? "Found: #{total} reports, #{count} have hits. Continue?[yes]", :green)
      puts '...exiting'
      exit 0
    end

    # Begin loading
    progress_bar = ProgressBar.new(count)
    begin
    seqfeature_ids = []
    # begin a transaction before making any changes
    BlastRun.transaction do
      puts "Loading data. If interuppted, all changes will be reverted."
      # initalize array to store feature ids
      # Create a new Blast run to store this report
      blast_run = BlastRun.new(
        :assembly => assembly,
        :blast_database => blast_db,
        :parameters => blast_file.parameters,
        :program => blast_file.program,
        :version => blast_file.version,
        :reference => blast_file.reference,
        :db => blast_file.db
      )
      blast_run.save! unless options[:test]
      # begin the iteration
      # xml_parser will create a 'report' object for every iteration
      # adding 'blanks' for missing iteration numbers (none hits)
      # Each report should have 1 iteration, report.hits is shorthand for report.iterations.last.hits
      blast_file.reports.each do |report|
        # move on if this query has no hits
        next unless report.hits.length > 0
        locus = concordance_hash[report.query_def] || report.query_def
        ## Lookup the feature_id from query_def
        if(options[:use_search_index])
          # Use the sunspot index to save time
          # This is not default in case the index is unavailable
          search = Seqfeature.search do
            with :locus_tag_value, locus
            with :assembly_id, options[:assembly_id]
            with :type_term_id, type_term_id
          end
          # verify that 1 and only 1 matching feature is found
          if search.total != 1
              say "Found #{search.total} features matching: '#{report.query_def}' ...skip?", :red
              if(yes? "(type 'y' or 'yes' to continue):")
                next
              else
                exit 0
              end
          else
            feature_id = search.hits.first.primary_key
          end
        else
          # Use the database if sunspot is not available
          features = Seqfeature.with_locus_tag(locus).includes(:bioentry).where('bioentry.assembly_id = ? and upper(display_name)=?',options[:assembly_id],options[:feature_type])
          feature = features.first
          if features.size != 1
            puts "Found #{features.length} results for #{iter.query_def} skipping"
            next
          else
            feature_id=feature.id
          end
        end
        # parse the hit data
        if hit = report.hits.first
          accession = hit.accession
          # remove splice variant number if requested
          if(options[:remove_splice])
            accession = accession.split(".")[0]
          end
          # get definition and verify length
          best_def = hit.definition
          if best_def.length > 4000
            best_def = best_def.slice(0..3999)
          end
        else
          accession = ''
          best_def = 'No Definition Found'
        end
        # create the new report entry text
        br = BlastReport.new(
          :blast_run => blast_run,
          :seqfeature_id => feature_id,
          :hit_acc => accession,
          :hit_def => best_def,
          :report => report
        )
        if br.valid?
          br.save! unless options[:test]
        else
          puts "Invalid BlastReport: #{br.inspect}"
        end
        seqfeature_ids << feature_id
        # all done ...next
        progress_bar.increment!
      end
    end
    rescue => e
      puts "**error: #{e}\n#{e.backtrace.join("\n")}"
      exit 0
    end
    # Begin Re-index
    if options[:test]
      reindex = ask('This is as test run, no changes were saved. Do you want to re-index the features anyway? To test re-indexing type \'yes\'; anything else to skip:')
    else
      reindex = 'yes'
    end
    if reindex =='yes'
      Seqfeature.reindex_all_by_id(seqfeature_ids)
    end
  end
  desc "create_db", 'Create a new blast database for attaching blast results'
  method_options %w(name -n) => :required,
    %w(link -l) => nil,
    %w(abbreviation -a) => nil,
    %w(taxon_id -t) => nil,
    %w(description -d) => nil
  def create_db
    taxon_id = (t = Taxon.find_by_taxon_id(options[:taxon_id])) ? t.taxon_id : nil
    b = BlastDatabase.new(
      :name => options[:name],
      :link_ref => options[:link],
      :abbreviation => options[:abbreviation],
      :taxon_id => taxon_id,
      :description => options[:description]
    )
    b.save!
  end
  
  desc 'list_db','Print information about blast databases'
  def list_db
    dbs = BlastDatabase.scoped
    puts "-\tID\tName\tAbbr\tTaxonID\tTaxonName\tDescription\tLink"
    dbs.each do |db|
      puts "\t#{db.id}\t#{db.name}\t#{db.abbreviation}\t#{db.taxon.try(:id)||'?'}\t#{db.taxon.try(:name)||'?'}\t#{db.description}\t#{db.link_ref}"
    end
  end
  
  desc 'list_run','Print information about blast databases'
  def list_run
    runs = BlastRun.scoped
    puts "-\tID\tDbName\tAssembly\tProgram\tVersion\tSystemFile\tParameters"
    runs.each do |run|
      puts "\t#{run.id}\t#{run.blast_database.name}\t#{run.assembly.name_with_version}\t#{run.program}\t#{run.version}\t#{run.db}\t#{run.parameters}"
    end
  end
end