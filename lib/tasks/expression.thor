class Expression < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  require 'progress_bar'
  # Insert expression results into the database. Expression is attached to an RNA-Seq experiment and a seqfeature
  # The file is expected to have at least three columns. The id (locus_tag) column, the count(mapped reads) column and the normalized(rpkm) column
  # These columns can be defined in the options with 1-based indexes
  # The file can be tab or comma delimited
  # --experiment/-e  => experiment name or id. Use 'experiment:list' to verify this before loading [Required]
  # --feature/-f  => type of feature expression will be assigned to. [Gene]
  # --id_column/-i  => id column index [1]
  # --count_column/-c  => count column index [2]
  # --normalized_column/-n  => rpkm column index [3]
  # --skip_not_found/-s => ignore id's in the file that cannot be found in the database [False]
  # --header/-h => header is present, ignore the first line [False]
  # --concordance/-d => concordance file, supply tab separated id mapping file with 'locus_tag  file_id'
  # --test/-t => test only, run the loader and check ids but do not commit any inserts
  desc 'load FILE',"Load feature counts into the database"
  method_options %w(experiment -e) => :required, :existing => 'raise', %w(feature -f) => 'Gene', 
    %w(id_column -i) => 1, %w(count_column -c) => 2, %w(normalized_column -n) => 3, %w(header -h) => false, 
    %w(test -t) => false, %w(skip_not_found -s) => false, %w(concordance -d) => nil
  def load(input_file)
    # Check input
    begin
      datafile = File.open(input_file,"r")
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    # Check Experiment
    experiment = RnaSeq.find_by_name(options[:experiment]) || RnaSeq.find_by_id(options[:experiment].to_i)
    unless experiment
      puts "experiment '#{options[:experiment]}' not found"
      exit 0
    end
    # Check and parse concordance
    concordance_hash={}
    if(options[:concordance])
      begin
        concordance_file = File.open(options[:concordance],"r")
        concordance_file.each do |line|
          locus_tag,file_id = line.chomp.split("\t")
          concordance_hash[file_id]=locus_tag
        end
      rescue
        puts "*** Error opening concordance *** \n#{$!}"
        exit 0
      end
    end
    # Parse the Input
    items = []
    number_reg = /^\d+\.{0,1}\d*$/
    datafile.each_with_index do |line,idx|
      # skip header if present
      next if (idx == 0) && options[:header]
      # skip any comment lines
      next if line[0] == '#'
      # open the file and check format
      if line.match(/\t/) 
        data = line.split("\t")
      else
        data = line.split(",")
      end
      next unless data.size >=3
      dataset = []
      # grab the columns
      dataset << data[options[:id_column]-1].gsub('"','')
      dataset << data[options[:count_column]-1].gsub('"','')
      dataset << data[options[:normalized_column]-1].gsub('"','')
      # check data
      next unless dataset[1].match(number_reg) && dataset[2].match(number_reg)
      items << dataset
    end
    # Verify Unique Input
    if (diff = items.size - items.uniq.size) != 0
      puts "There were #{diff} non-unique locus lines in the file."
      puts "#{items - items.uniq}"
      exit 0
    end
    # check existing counts
    if (counts = experiment.feature_counts.includes(:seqfeature).where{upper(seqfeature.display_name)==my{options[:feature]}}.count) == 0
      puts "Experiment looks good"
    else
      case options[:existing]
      when 'truncate'
        puts "truncating existing feature counts for experiment #{experiment.name}"
        FeatureCount.where(:experiment_id => experiment.id).delete_all
      when 'merge'
        # delete existing later
      when 'raise'
        puts "Experiment already has #{counts} #{options[:feature]}s with expression. You need to supply an :existing option of 'truncate','append' or 'override' to continue"
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
        features = Seqfeature.find_all_with_locus_tags(batch_ids).where{bioentry.taxon_version_id==my{experiment.taxon_version_id}}
        features = features.where{upper(display_name) == my{options[:feature]}}
        seqfeature_ids.concat(features.map(&:seqfeature_id))
        feature_ids = features.collect{|f|f.locus_tag.value}
        # check for missing locus
        if feature_ids.size < batch_ids.size
          puts "#{(batch_ids - feature_ids).size} features were not found in this batch:\n#{batch_ids - feature_ids}"
          if options[:skip_not_found]
            puts "\n-s supplied, ignoring missing features...\n"
          else
            exit 0
          end
        end
        # Save the new records
        unless options[:test]
          features.each do |feature|
            if(options[:existing]=='merge')
              if f = experiment.features.find_by_id(feature.id)
                f.delete
              end
            end
            FeatureCount.fast_insert(
              :seqfeature_id => feature.id,
              :experiment_id => experiment.id,
              :count => batch_hsh[feature.locus_tag.value][1],
              :normalized_count => batch_hsh[feature.locus_tag.value][2]
            )
          end
        end
        # update progress
        progress_bar.increment!(batch.length)
      end
    end#End Transaction
    # Begin Re-index
    if options[:test]
      reindex = ask('This is as test run, no changes were saved. Do you want to re-index the features anyway? To test re-indexing type \'yes\'; anything else to skip:')
    else
      reindex = 'yes'
    end
    if reindex =='yes'
      Seqfeature.reindex_all_by_id(seqfeature_ids)
    end
    puts "..Done"
  end#End load method
end
