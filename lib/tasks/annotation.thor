class Annotation < Thor
  desc 'by_blast FILE',"Load annotations from file based on blast best hit accession"
  method_options %w(new_annotation -a) => :required,
  %w(id_column -i) => 1, %w(anno_column -c) => 2, :no_index => false
  method_option :header, :aliases => '-h', :desc => 'Supply flag if a header is present'
  method_option :feature_type, :aliases => '-f', :desc => 'If supplied will only annotate given type'
  method_option :blast_run, :aliases => '-b', :required => true, :desc  => 'Id of blast run for lookup'
  method_option :ontology, :aliases => '-o', :required => true, :desc => 'Name or Id of ontology for new terms'
  method_option :skip_missing, :aliases => '-s', :default => false, :desc => 'Supply flag to skip missing items.'
  method_option :test, :aliases => '-t', :default => false, :desc => "Supply to perform test only run with no data changes"
  def by_blast(input_file)
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
    ontology = Bio::Ontology.find_by_name(options[:ontology]) || Bio::Ontology.find_by_ontology_id(options[:ontology])
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
    count_table.keys.sort.each{|key| puts " - #{count_table[key]} \t#{key} time#{key>1 ? 's' : ''}"}
    puts "---"
    # report uniq counts
    items.each{|key,arr| c=arr.uniq.length;(uniq_count_table[c]||=0);uniq_count_table[c]+=1}
    uniq_count_table.keys.sort.each{|key| puts " - #{uniq_count_table[key]} \t#{key} uniq value#{key>1 ? 's' : ''}"}
    # initial setup
    features = []
    # Wrap in a transaction to avoid partial load
    begin
    Bio::Feature::Seqfeature.transaction do
      # First get the new term
      puts "Find or Create - #{ontology.name} :: #{options[:new_annotation]}"
      new_term = Term.find_or_create_by_name_and_ontology_id(options[:new_annotation],ontology.id)
      # Start progress meter and begin the main loop
      progress_bar = ProgressBar.new(items.length)
      items.each do |key,values|
        # grab Seqfeatures using seqfeature ids from reports with this key
        features = Bio::Feature::Seqfeature.where{seqfeature_id.in(BlastReport.select('seqfeature_id').where{hit_acc==my{key}}.where{blast_run_id==my{blast_run.id}})}
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
            Bio::Feature::Seqfeature.connection.execute("INSERT INTO SEQFEATURE_QUALIFIER_VALUE (seqfeature_id,term_id,value,rank)
            VALUES(#{feature.id},#{new_term.id},'#{value}',#{idx+1})")
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
end