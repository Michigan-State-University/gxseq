class Annotation < Thor
  desc 'tag_blast FILE',"Load annotations from file based on blast best hit accession"
  method_options %w(new_annotation -a) => :required,
  %w(id_column -i) => 1, %w(anno_column -c) => 2, :no_index => false
  method_option :header, :aliases => '-h', :desc => 'Supply flag if a header is present'
  method_option :feature_type, :aliases => '-f', :desc => 'If supplied will only annotate given type'
  method_option :blast_run, :aliases => '-b', :required => true, :desc  => 'Id of blast run for lookup'
  method_option :ontology, :aliases => '-o', :required => true, :desc => 'Name or Id of ontology for new terms'
  method_option :test, :aliases => '-t', :default => false, :desc => "Supply to perform test only run with no data changes"
  method_option :verbose, :aliases => '-v', :default => false, :desc => "Supply for verbose output"
  method_option :use_search, :aliases => '-s', :default => false, :desc => "Use indexed searching for faster lookup"
  def tag_blast(input_file)
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    require 'csv'
    # Check input
    begin
      datafile = File.open(input_file,"r")
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    # Check blast
    blast_run = BlastRun.find_by_id(options[:blast_run])
    unless blast_run
      puts "Blast Run '#{options[:blast_run]}' not found. Try: thor blast:list_runs for help"
      exit 0
    end
    ontology = Biosql::Ontology.find_by_name(options[:ontology]) || Biosql::Ontology.find_by_ontology_id(options[:ontology])
    unless ontology
      puts "Ontology '#{options[:ontology]}' not found."
      exit 0
    end
    # Parse the Input
    items = {}
    number_reg = /^\d+\.{0,1}\d*$/
    datafile.each_with_index do |line,idx|
      # skip header if present
      next if (idx == 0) && options[:header]
      # skip any comment lines
      next if line[0] == '#'
      # open the file and check format
      if line.match(/\t/) 
        data = line.parse_csv({ :col_sep => "\t" })
      else
        data = line.parse_csv
      end
      next unless data.size > 1
      # grab the columns in a hash of arrays :id => [val1,val2] because we can have multiple values
      items[data[options[:id_column]-1]] ||=[]
      items[data[options[:id_column]-1]] << data[options[:anno_column]-1]
    end
    # Report Input
    puts "Found #{total_items = items.length} ids"
    count_table = {}
    uniq_count_table = {}
    # Report total counts
    items.each{|key,arr| c=arr.length;(count_table[c]||=0);count_table[c]+=1}
    if(options[:verbose])
      count_table.keys.sort.each{|key| puts " - #{count_table[key]} \t#{key} time#{key>1 ? 's' : ''}"}
    end
    puts "---"
    # report uniq counts
    items.each{|key,arr| c=arr.uniq.length;(uniq_count_table[c]||=0);uniq_count_table[c]+=1}
    if(options[:verbose])
      uniq_count_table.keys.sort.each{|key| puts " - #{uniq_count_table[key]} \t#{key} uniq value#{key>1 ? 's' : ''}"}
    end
    # initial setup
    features = []
    # Wrap in a transaction to avoid partial load
    begin
    Biosql::Feature::Seqfeature.transaction do
      # First get the new term
      puts "Find or Create - #{ontology.name} :: #{options[:new_annotation]}" if options[:verbose]
      new_term = Biosql::Term.find_or_create_by_name_and_ontology_id(options[:new_annotation],ontology.id)
      # Start progress meter and begin the main loop
      progress_bar = ProgressBar.new(items.length)
      items.each do |key,values|
        # grab Seqfeatures using seqfeature ids from reports with this key
        if(options[:use_search])
          search = Biosql::Feature::Seqfeature.search do |s|
            s.dynamic :blast_acc do
              with("blast_#{blast_run.id}",key)
            end
            if(options[:feature_type])
              s.with :display_name, options[:feature_type]
            end
          end
          puts "#{search.total} features with blast_hit #{key}" if options[:verbose]
          search.hits.each do |hit|
            # Add a new qualifier for each value
            values.uniq.each_with_index do |value,idx|
              next if value.blank?
              if(options[:verbose])
                puts "Adding #{new_term.name} - feature id: #{hit.stored(:id)}, value: #{value}"
              end
              # We cannot use the fast_insert method because of composite keys and active_record is quite slow so we insert by hand
              Biosql::Feature::Seqfeature.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
              VALUES(#{hit.stored(:id)},#{new_term.id},'#{value}',#{idx+1})")
            end
          end
        else
          features = Biosql::Feature::Seqfeature.where{seqfeature_id.in(BlastReport.select('seqfeature_id').where{hit_acc==my{key}}.where{blast_run_id==my{blast_run.id}})}
          puts "#{features.length} features with blast_hit #{key}" if options[:verbose]
          features.each do |feature|
            if(options[:feature_type]&&feature.display_name!=options[:feature_type])
              next
            end
            # Add a new qualifier for each value
            values.uniq.each_with_index do |value,idx|
              next if value.blank?
              if(options[:verbose])
                puts "Adding #{new_term.name} - feature id: #{feature.id}, type: #{feature.display_name}, value: #{value}"
              end
              # We cannot use the fast_insert method because of composite keys and active_record is quite slow so we insert by hand
              Biosql::Feature::Seqfeature.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
              VALUES(#{feature.id},#{new_term.id},'#{value}',#{idx+1})")
            end
          end
        end
        # done
        progress_bar.increment!
      end # items loop
      if options[:test]
        raise 'Transaction not committed test only flag set'
      end
    end # transaction
    rescue => e
      puts e
      if options[:verbose]
        puts e.backtrace.join("/n")
      end
    end
  end
  
  desc 'bubble', "Copy annotations from CDS and mRNA to Gene parent. Configure bubble terms in settings.yml"
  method_option :assembly, :aliases => '-a', :desc => 'ID of Assembly to annotate'
  method_option :test_only, :aliases => '-t', :desc => 'Test run with no database changes'
  def bubble
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    unless APP_CONFIG[:bubble_up_terms]
      puts "No bubble up terms defined."
      return false
    end
    if(options[:assembly])
      assembly = ::Assembly.find_by_id(options[:assembly])
      unless assembly
        puts "Assembly '#{options[:assembly]}' not found. Try thor assembly:list"
        return false
      end
      b_ids = assembly.bioentries.select("bioentry_id").except(:order)
    end
    if options[:assembly]
      genes = Biosql::Feature::Gene.includes(:bioentry, :gene_models=>[:cds, :mrna])
      genes = genes.where{bioentry.assembly_id == my{assembly.id}}
    else
      genes = Biosql::Feature::Gene.includes(:gene_models=>[:cds, :mrna])
    end
    progress_bar = ProgressBar.new(genes.count)
    bubble_terms = Biosql::Term.where{lower(name).in my{APP_CONFIG[:bubble_up_terms]}}
    if bubble_terms.empty?
      puts "No bubble terms found for: #{APP_CONFIG[:bubble_up_terms].join(',')}"
      return false
    end
    Biosql::Feature::Gene.transaction do
      genes.find_in_batches(:batch_size => 500) do |batch|
        batch.each do |gene|
          bubble_terms.each do |bterm|
            cur_vals = gene.bubble_qualifiers.select{|q| q.term_id==bterm.term_id}.map(&:value)
            rank = cur_vals.length+1
            cds_vals, mrna_vals = [],[]
            gene.gene_models.each do |gm|
              if(gm.cds)
                cds_vals << gm.cds.bubble_qualifiers.select{|q| q.term_id==bterm.term_id}.map(&:value)
              end
              if(gm.mrna)
                mrna_vals << gm.mrna.bubble_qualifiers.select{|q| q.term_id==bterm.term_id}.map(&:value)
              end
            end
            new_vals = (cds_vals.flatten+mrna_vals.flatten).uniq - cur_vals
            new_vals.each do |new_val|
              if options[:test_only]
                puts "Gene: #{gene.id} - #{bterm.name}: #{rank}-#{new_val}"
              else
                ActiveRecord::Base.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
                VALUES(#{gene.id},#{bterm.id},'#{new_val.gsub(/\'/,"''")}',#{rank})")
              end
              rank +=1
            end
          end
        end
        progress_bar.increment!(batch.length)
      end
    end
  end
  
  desc 'load FILE', "Add new annotations from a file with id's matching the chosen feature/qualifier"
  method_options %w(id_column -i) => 1, %w(anno_column -c) => 2, :no_index => false
  method_option :name, :aliases => '-n', :required => true, :desc => 'Name of new or existing annotation'
  method_option :ontology, :aliases => '-o', :required => true, :desc => 'Name or ID of ontology for new terms'
  method_option :assembly, :aliases => '-a', :required => true, :desc => 'ID of Assembly to annotate'
  method_option :header, :aliases => '-h', :desc => 'Supply flag if a header is present'
  method_option :qualifier, :aliases => '-q', :default => 'locus_tag', :desc  => 'Name of qualifier to use for lookup'
  method_option :feature_type, :aliases => '-f', :desc => 'Only annotate given type if supplied'
  method_option :test, :aliases => '-t', :default => false, :desc => "Supply to perform test only run with no data changes"
  method_option :verbose, :aliases => '-v', :desc => "Flag for verbose output"
  method_option :remove_splice, :aliases => '-r', :desc => "Remove splice variant (transcript). Id becomes everything prior to first '.'"
  def load(input_file)
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    require 'csv'
    # Check input
    begin
      datafile = File.open(input_file,"r")
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    # Check ontology
    ontology = Biosql::Ontology.find_by_name(options[:ontology]) || Biosql::Ontology.find_by_ontology_id(options[:ontology])
    unless ontology
      puts "Ontology '#{options[:ontology]}' not found."
      exit 0
    end
    assembly = ::Assembly.find_by_id(options[:assembly])
    unless assembly
      puts "Assembly '#{options[:assembly]}' not found. Try thor assembly:list"
      exit 0
    end
    
    # Parse the Input
    items = {}
    number_reg = /^\d+\.{0,1}\d*$/
    datafile.each_with_index do |line,idx|
      # skip header if present
      next if (idx == 0) && options[:header]
      # skip any comment lines
      next if line[0] == '#'
      # open the file and check format
      if line.match(/\t/) 
        data = line.parse_csv({ :col_sep => "\t" })
      else
        data = line.parse_csv
      end
      next unless data.size > 1
      # get the key
      key = data[options[:id_column]-1]
      # Remove splice variants
      if options[:remove_splice]
        key = key.split(".")[0]
      end
      # grab the columns in a hash of arrays :id => [val1,val2] because we might have multiple entries for the same id
      items[key] ||=[]
      items[key] << data[options[:anno_column]-1]
    end
    # Report Input
    puts "Found #{total_items = items.length} ids"
    count_table = {}
    uniq_count_table = {}
    # Report total counts
    items.each{|key,arr| c=arr.length;(count_table[c]||=0);count_table[c]+=1}
    count_table.keys.sort.each{|key| puts " - #{count_table[key]} \t#{key} time#{key>1 ? 's' : ''}"}
    puts "---"
    # report uniq counts
    items.each{|key,arr| c=arr.uniq.length;(uniq_count_table[c]||=0);uniq_count_table[c]+=1}
    uniq_count_table.keys.sort.each{|key| puts " - #{uniq_count_table[key]} \t#{key} uniq value#{key>1 ? 's' : ''}"}
    # initial setup
    features = []
    # Wrap in a transaction to avoid partial load
    begin
    Biosql::Feature::Seqfeature.transaction do
      features_needing_index = []
      # First get the new term
      puts "Setup Name For - #{ontology.name} :: #{options[:name]}"
      new_term = Biosql::Term.find_or_create_by_name_and_ontology_id(options[:name],ontology.id)
      # Start progress meter and begin the main loop
      progress_bar = ProgressBar.new(items.length)
      items.each do |key,values|
        # grab Seqfeatures using qualifier term name
        features = Biosql::Feature::Seqfeature.includes(:bioentry,[:qualifiers => :term])
          .where{qualifiers.term.name == my{options[:qualifier]}}
          .where{bioentry.assembly_id == my{assembly.id}}
          .where{qualifiers.value == my{key}}
        # limit type if supplied
        features = features.where{upper(display_name)==my{options[:feature_type].upcase}} if options[:feature_type]
        features.each do |feature|
          features_needing_index << feature.id
          # Add a new qualifier for each uniq value
          values.uniq.each_with_index do |value,idx|
            #TODO: fix idx/rank for pre-exisiting qualifier
            next if value.blank?
            if(options[:verbose])
              puts "Adding #{new_term.name} - feature id: #{feature.id}, type: #{feature.display_name}, value: #{value}"
            end
            # We cannot use the fast_insert method because of composite keys and active_record is quite slow so we insert by hand
            Biosql::Feature::Seqfeature.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
            VALUES(#{feature.id},#{new_term.id},'#{value.gsub(/\'/,"''")}',#{idx+1})")
          end
        end
        # done
        progress_bar.increment!
      end # items loop
      puts "Updated #{features_needing_index.length} matching features"
      if options[:test]
        raise 'Transaction not committed test only flag set'
      end
      # Index
      Biosql::Feature::Seqfeature.reindex_all_by_id(features_needing_index) unless options[:no_index]
    end # transaction
    rescue => e
      puts e
      if options[:verbose]
        puts e.backtrace.join("/n")
      end
    end
  end
end
