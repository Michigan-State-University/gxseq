class Blast < Thor
  #TODO: Add Desc text to all tasks and update docs
  ENV['RAILS_ENV'] ||= 'development'
  desc "create_run FILE", 'load xml formatted blast results into the database'
  method_options %w(blast_db -b) => :required,
    %w(assembly_id -a) => :required,
    %w(remove_splice -r) => false,
    %w(use_search_index -u) => false,
    %w(limit_hits -h) => nil,
    %w(feature_type -f) => 'Gene', %w(concordance -d) => nil,
    :test => false
  def create_run(input_file)
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # verify database
    blast_db = BlastDatabase.find_by_name(options[:blast_db]) || BlastDatabase.find_by_id(options[:blast_db])
    unless blast_db
      puts "Could not find blast database: #{options[:blast_db]}"
      exit 0
    end
    # verify taxon
    assembly = ::Assembly.find_by_id(options[:assembly_id])
    unless assembly
      puts "Could not find assembly with id:#{options[:assembly_id]}"
      exit 0
    end
    # verify type if provided
    if(options[:feature_type])
      unless type_term = Biosql::Term.where{(upper(name)==my{options[:feature_type].upcase}) & (ontology_id == Biosql::Term.seq_key_ont_id)}.first
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
    # Parse input
    begin
      puts "Opening blast report ... this could take a while"
      open_blast = File.open(input_file,'r')
      blast_file = Bio::Blast::Report.xmlparser(open_blast)
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    # Count iterations
    puts "Counting iterations"
    count = 0
    total = 0
    blast_file.reports.each do |report|
      total +=1 
      count +=1 if report.hits.length > 0
    end
    say "Found: #{total} reports, #{count} have hits", :green

    # Begin loading
    progress_bar = ProgressBar.new(count)
    begin
    # begin a transaction before making any changes
    BlastRun.transaction do
      PaperTrail.enabled = false
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
      
      GC.disable
      gci = 0
      blast_file.reports.each do |report|
        # move on if this query has no hits
        next unless report.hits.length > 0
        # puts "Report # #{gci} -  Hits: #{report.hits.length} - Total Hsps: #{report.hits.collect{|h| h.hsps.length}.sum}"
        gci += 1
        query_def = report.query_def.split(" ")[0]
        locus = concordance_hash[query_def] || query_def
        ## Lookup the feature_id from query_def
        if(options[:use_search_index])
          # Use the sunspot index to save time
          # This is not default in case the index is unavailable
          search = Biosql::Feature::Seqfeature.search do
            with :locus_tag, locus
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
          features = Biosql::Feature::Seqfeature.with_locus_tag(locus)
            .includes(:bioentry)
            .where{bioentry.assembly_id == my{options[:assembly_id]}}
            .where{seqfeature.type_term_id==my{type_term.id}}
          feature = features.first
          if features.size != 1
            puts "Found #{features.length} results for #{report.query_def} skipping"
            next
          else
            feature_id=feature.id
          end
        end
        
        BlastRun.populate_blast_iteration(blast_run.id,report,feature_id,options)
        if gci % 100 == 0
          GC.enable
          GC.start
          GC.disable
        end
        # all done ...next
        progress_bar.increment!
      end
    end
    rescue => e
      puts "**error: #{e}\n#{e.backtrace.join("\n")}"
      exit 0
    end
    # Clear memory
    GC.enable
    blast_file=nil
    GC.start
    
    PaperTrail.enabled = true
    # Begin Re-index
    if options[:test]
      reindex = ask('This is as test run, no changes were saved. Do you want to re-index the features anyway? To test re-indexing type \'yes\'; anything else to skip:')
    else
      reindex = 'yes'
    end
    if reindex =='yes'
      `/bin/bash -c 'RAILS_ENV=#{ENV['RAILS_ENV']} thor assembly:index_features -a #{options[:assembly_id]}'`
    end
    puts "\n..done"
  end
  
  desc "delete_run", "Remove blast run and all dependent blast_reports"
  method_option :blast_run, :aliases => '-b', :desc => 'ID of blast run to remove'
  method_option :reindex, :aliases => '-r', :default => false, :desc => 'Re-index features'
  def delete_run
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    blast_run = BlastRun.find_by_id(options[:blast_run])
    unless blast_run
      puts "No blast run found for: #{options[:blast_run]}"
      exit 0
    end
    puts "Found Blast Run: #{blast_run.id} - #{blast_run.name_with_description}"
    puts "\t-- #{blast_run.blast_iterations.count} blast iterations"
    remove_run = ask("To delete permanently type \'yes\'; anything else to skip:")
    begin
      if remove_run == 'yes'
        blast_run_assembly = blast_run.assembly
        blast_run.destroy
        puts "..deleted"
        if(blast_run_assembly && options[:reindex])
          puts "reindexing assembly features"
          `/bin/bash -c 'RAILS_ENV=#{ENV['RAILS_ENV']} thor assembly:index_features -a #{blast_run_assembly.id}'`
          puts "\n..done"
        end
      else
        puts '..skipped'
      end
    rescue => e
      puts "Error removing blast run:\n"
      puts e
    end
  end
  
  desc "annotate FILE", "Annotate blast results based on hit accession. Accepts 1 column file with accessions"
  method_option :blast_run, :aliases => '-b', :desc => 'ID of blast run to annotate'
  method_option :annotation, :aliases => '-a', :required => true, :desc  => 'Annotation string to add'
  method_option :test_only, :aliases => '-t', :default => false, :desc => 'Do not save changes only test lookup and report counts'
  def annotate(input_file)
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    blast_run = BlastRun.find_by_id(options[:blast_run])
    unless blast_run
      puts "No blast run found for: #{options[:blast_run]}"
      exit 0
    end
    puts "Importing file accessions"
    id_hash = {}
    File.open(input_file).each do |line|
      id_hash[line.strip.chomp] = true
    end
    puts "Found #{id_hash.length}. First few lines: #{id_hash.keys[0,5].to_sentence}. Last line: #{id_hash.keys.last}"
    bar = ProgressBar.new(blast_run.blast_reports.count)
    matched = 0
    puts "working on #{blast_run.blast_reports.count} reports"
    BlastReport.transaction do
      blast_run.blast_reports.select('id,hit_def,hit_acc').find_in_batches(:batch_size => 500) do |batch|
        batch.each do |report|
          if id_hash[report.hit_acc]
            matched +=1
            unless(options[:test_only])
              report.update_attribute(:hit_def, "#{report.hit_def} #{options[:annotation]}")
            end
          end
        end
        bar.increment!(batch.length)
      end
      puts "Found #{matched} matching reports"
    end
  end
  
  desc "create_db", 'Create a new blast database for attaching blast results'
  method_options %w(name -n) => :required,
    %w(link -l) => nil,
    %w(filepath -p) => nil,
    %w(taxon_id -t) => nil,
    %w(description -d) => nil,
    %w(group -g) => nil
  def create_db
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    taxon_id = (t = Biosql::Taxon.find_by_taxon_id(options[:taxon_id])) ? t.taxon_id : nil
    group=nil
    if(options[:group])
      group = ::Group.find_by_name(options[:group]) || Group.find_by_id(options[:group]) || nil
      unless group
        puts "Could not find group: '#{options[:group]}'"
        return
      end
    end
    b = BlastDatabase.new(
      :name => options[:name],
      :link_ref => options[:link],
      :filepath => options[:filepath],
      :taxon_id => taxon_id,
      :description => options[:description],
      :group => group
    )
    b.save!
  end
  
  desc 'list_db','Print information about blast databases'
  def list_db
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    dbs = BlastDatabase.order(:name)
    table = Terminal::Table.new :headings => ['#','ID', 'Name', 'Path', 'Group', 'Taxon', 'Description'] do |t|
      dbs.each_with_index do |b,idx|
        t << [idx, b.id, b.name, b.filepath, b.group.try(:name),
          "#{b.taxon.try(:ncbi_taxon_id)}::#{b.taxon.try(:name)}", b.description]
      end
    end
    puts table
  end
  
  desc 'list_run','Print information about blast databases'
  method_option :include_user, :aliases => '-u', :default => false, :desc => "Include user initiated runs"
  def list_run
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    runs = BlastRun.includes(:blast_database).order("blast_databases.name ASC")
    table = Terminal::Table.new :headings => ['#','ID', 'DB Name', 'Assembly', 'Program'] do |t|
      runs.where{assembly_id != nil}.each_with_index do |r,idx|
        t << [idx, r.id, r.blast_database.name, "#{r.assembly.id}::#{r.assembly.name_with_version}", r.program]
      end
    end
    puts table
    if(options[:include_user])
      puts "\nUser Runs"
      table = Terminal::Table.new :headings => ['#','ID', 'DB Name', 'User', 'Program'] do |t|
        runs.where{assembly_id == nil}.each_with_index do |r,idx|
          t << [idx, r.id, r.blast_database.name, r.user.try(:login), r.program]
        end
      end
      puts table
    end
  end
  
  desc 'fix_tair', 'Fix a tair annotation by removing "| Symbols:" and "| chr.*"'
  method_option :blast_run, :aliases => '-b', :required => true, :desc => 'ID of blast run to annotate'
  def fix_tair
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    unless BlastRun.find_by_id(options[:blast_run])
      puts "No blast run found for: #{options[:blast_run]}"
      exit 0
    end
    puts ActiveRecord::Base.connection.update("
      update (
          select regexp_replace(definition,'\\| Symbols: (.+) \\| chr.+$','\\1') new_def, definition
          from hits
          left outer join blast_iterations on blast_iterations.id = hits.blast_iteration_id
          where blast_iterations.blast_run_id = #{options[:blast_run]}
        ) sub_blast
        set sub_blast.definition = sub_blast.new_def
    ")
  end
  
  desc "transfer", "Transfer each serialized blast report to 3rd normal form structure"
  method_options %w(blast_run -b) => :required
  def transfer
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    blast_run = BlastRun.find_by_id(options[:blast_run])
    unless blast_run
      puts "No blast run found for: #{options[:blast_run]}"
      exit 0
    end
    bar = ProgressBar.new(blast_run.blast_reports.count)
    matched = 0
    puts "working on #{blast_run.blast_reports.count} reports"
    BlastReport.transaction do
      blast_run.blast_reports.select('id,seqfeature_id,report').find_in_batches(:batch_size => 500) do |batch|
        batch.each do |blast_report|
          blast_report.report.iterations.each do |iteration|
            BlastRun.populate_blast_iteration(blast_run.id,iteration,blast_report.seqfeature_id)
            matched += 1
          end
        end
        bar.increment!(batch.length)
      end
      puts "Found #{matched} matching reports"
    end
  end
  
  # desc "statistics", "Get statistics from a blast file"
  # def statistics(input_file)
  #   require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
  #   puts "Opening blast report ... this could take a while"
  #   open_blast = File.open(input_file,'r')
  #   
  #   array = []
  #   open_blast.each do |line|
  #     if line.match(/Hsp_align-len/)
  #       # puts line.scan(/\d+/)
  #       array.push(line.scan(/\d+/))
  #     end
  #   end
  #   
  #   puts array.size
  #   puts array.sum / array.size
  #   puts array.sort.last
  # end
end