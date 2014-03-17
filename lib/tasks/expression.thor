class Expression < Thor
  ENV['RAILS_ENV'] ||= 'development'
  # Insert expression results into the database. Expression is attached to an RNA-Seq sample and a seqfeature
  # The file is expected to have at least three columns. The id (locus_tag) column, the count(mapped reads) column and the normalized(rpkm) column
  # These columns can be defined in the options with 1-based indexes
  # The file can be tab or comma delimited
  # --sample/-e  => sample name or id. Use 'sample:list' to verify this before loading [Required]
  # --feature/-f  => type of feature expression will be assigned to. [Gene]
  # --id_column/-i  => id column index [1]
  # --count_column/-c  => count column index [2]
  # --normalized_column/-n  => rpkm column index [3]
  # --skip_not_found/-s => ignore id's in the file that cannot be found in the database [False]
  # --header/-h => header is present, ignore the first line [False]
  # --concordance/-d => concordance file, supply tab separated id mapping file with 'locus_tag  file_id'
  # --test/-t => test only, run the loader and check ids but do not commit any inserts
  desc 'load FILE',"Load feature counts into the database"
  method_options :existing => 'raise', 
    %w(id_column -i) => 1, %w(count_column -c) => 2, %w(unique_column -q) => 3, %w(normalized_column -n) => 4, %w(header -h) => false, 
    %w(test -t) => false, %w(skip_not_found -s) => false, %w(concordance -d) => nil, :no_index => false
  method_option :feature_type, :aliases => '-f', :required => true, :desc => 'Supply the feature type. "Mrna" for a transcriptome.'
  method_option :use_search_index, :aliases => '-u', :default => false
  method_option :assembly_id, :aliases => '-a', :type => :numeric, :required => true, :desc => 'Supply the ID for sequence taxonomy. Use thor taxonomy:list to lookup'
  method_option :sample, :desc => 'Supply exact sample name for lookup'
  method_option :sample_def, :desc => 'Supply text to find sample by description. Ignored if --sample/-e provided'
  def load(input_file)
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    require 'progress_bar'
    # Check input
    if(options[:normalized_column]<=0)
      puts "Normalized column >= 0 required"
      exit 0
    end
    begin
      datafile = File.open(input_file,"r")
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    unless ::Assembly.find_by_id(options[:assembly_id])
      puts "No taxon with id #{options[:assembly_id]} found. Try: thor taxonomy:list"
      return
    end
    # Check Sample
    if(options[:sample])
      sample = RnaSeq.find_by_name_and_assembly_id(options[:sample],options[:assembly_id]) || RnaSeq.find_by_id(options[:sample].to_i)
    elsif(options[:sample_def])
      samples = RnaSeq.where{assembly_id==my{options[:assembly_id]}}.where{description =~ my{"%#{options[:sample_def]}%"} }
      if(samples.count>1)
        puts "--sample_def was not unique: #{samples.count} samples matched"
        exit 0
      else
        sample = samples.first
      end
    else
      sample = nil
    end
    unless sample
      puts "sample '#{options[:sample]||options[:sample_def]}' not found"
      exit 0
    end
    # verify type if provided
    if(options[:feature_type])
      unless type_term = Biosql::Term.where{(name==my{options[:feature_type]}) & (ontology_id == Biosql::Term.seq_key_ont_id)}.first
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
    # Parse the Input
    items = []
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
      next unless data.size >=3
      dataset = []
      # grab the columns
      dataset << data[options[:id_column]-1]
      dataset << (options[:count_column]<=0 ? nil : data[options[:count_column]-1].to_i)
      dataset << data[options[:normalized_column]-1].to_f
      dataset << (options[:unique_column]<=0 ? nil : data[options[:unique_column]-1].to_i)
      items << dataset
    end
    # check existing counts
    if (counts = sample.feature_counts.includes(:seqfeature).where{seqfeature.display_name==my{options[:feature]}}.count) == 0
      puts "Sample looks good"
    else
      case options[:existing]
      when 'truncate'
        puts "truncating existing feature counts for sample #{sample.name}"
        FeatureCount.where(:sample_id => sample.id).delete_all
      when 'raise'
        puts "Sample already has #{counts} #{options[:feature]}s with expression. You need to supply an :existing option of 'truncate','append' or 'override' to continue"
        exit 0
      else
        puts "Invalid :existing option found"
        exit 0
      end
    end
    # report progress
    puts "Found #{total_items = items.size} datapoints"
    if(options[:test])
      puts "--test supplied, will not save any changes"
    end
    progress_bar = ProgressBar.new(total_items)
    seqfeature_ids = []
    # Begin Transcation
    FeatureCount.transaction do
      # Process the file data in chunks
      idx = 0
      items.each_slice(999) do |batch|
        seqfeature_ids = []
        feature_ids = []
        # build file data lookup hash
        idx+=batch.size
        batch_ids = []
        batch_hsh = {}
        batch.each do |item|
          concordance_hash[item[0]] ||= item[0]
          batch_ids << concordance_hash[item[0]]
          batch_hsh[concordance_hash[item[0]]]=item
        end
        # Grab all of the matching features
        if(options[:use_search_index])
          # Use the sunspot index to save time
          # This is not default in case the index is unavailable
          search = Biosql::Feature::Seqfeature.search do
            with :locus_tag, batch_ids
            with :assembly_id, options[:assembly_id]
            with :type_term_id, type_term_id
            paginate(:page => 1, :per_page => 999)
          end
          # verify that 1 and only 1 matching feature is found
          seqfeature_ids = search.hits.collect{|hit| hit.stored(:id)}
          feature_ids = search.hits.collect{|hit| hit.stored(:locus_tag)}
        else
          features = Biosql::Feature::Seqfeature.find_all_with_locus_tags(batch_ids)
            .includes(:bioentry,:qualifiers => [:term])
            .where{bioentry.assembly_id == my{sample.assembly_id}}
            .where{seqfeature.type_term_id == my{type_term_id}}
          # Add Id's to the running total array
          seqfeature_ids.concat(features.map(&:seqfeature_id))
          # Collect the locus tags for this batch
          feature_ids = features.collect{|f|f.locus_tag.value}
        end
        # check for missing locus
        if feature_ids.size != batch_ids.size
          puts "#{(batch_ids - feature_ids).size} features were not found in this batch:\n#{[batch_ids - feature_ids][0,5]} ..."
          if options[:skip_not_found]
            puts "\n-s supplied, ignoring missing features...\n"
          else
            exit 0
          end
        end
        # print out a sample insert if test-only
        if options[:test]
          seqfeature_id = seqfeature_ids.first
          locus_tag = feature_ids.first
          puts "Sample FeatureCount::
            seqfeature=>#{seqfeature_id},
            sample=>#{sample.id},
            count=>#{batch_hsh[locus_tag][1]},
            normalized=>#{batch_hsh[locus_tag][2]}"
        # Save the new records
        else
          seqfeature_ids.each_with_index do |seqfeature_id,index|
            FeatureCount.fast_insert(
              :seqfeature_id => seqfeature_id,
              :sample_id => sample.id,
              :count => batch_hsh[feature_ids[index]][1],
              :normalized_count => batch_hsh[feature_ids[index]][2],
              :unique_count => batch_hsh[feature_ids[index]][3]
            )
          end
        end
        # update progress
        progress_bar.increment!(batch.length)
      end
    end#End Transaction
    # Begin Re-index
    if options[:test]
      reindex = ask('This is a test run, no changes were saved. Do you want to re-index the features anyway? To test re-indexing type \'yes\'; anything else to skip:')
    else
      reindex = options[:no_index] ? 'no' : 'yes'
    end
    if reindex =='yes'
      Assembly.find(assembly_id).reindex_features
    end
    puts "..Done"
  end#End load method
end
