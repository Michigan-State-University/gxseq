class Expression < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')

  desc 'load',"Load feature counts into the database"
  method_options %w(verbose -v) => false, %w(multiple -m) => false, %w(experiment -e) => :required, :existing => 'raise'
  def load(input_file)
    # Check input
    begin
      datafile = File.open(input_file,"r")
    rescue
      puts "*** Error opening input *** \n#{$!}"
      exit 0
    end
    # Check Experiment
    experiment = RnaSeq.find_by_name options[:experiment]
    unless experiment
      puts "experiment '#{options[:experiment]}' not found"
      exit 0
    end
    
    items = []
    datafile.each do |line|
      # open the file and check format
      data = line.split("\t")
      next unless data.size >=3
      # skip any comment/header lines
      next if line[0] == '#'
      number_reg = /^\d+\.{0,1}\d*$/
      next unless data[1].match(number_reg) && data[2].match(number_reg)
      items << data
    end
    if (diff = items.size - items.uniq.size) != 0
      puts "There were #{diff} non-unique locus lines in the file."
      exit 0
    end
    puts "Found #{total_items = items.size} datapoints"
    FeatureCount.transaction do
      # check existing counts
      if (counts = experiment.feature_counts.count) == 0
        puts "Experiment looks good"
      else
        case options[:existing]
        when 'truncate'
          puts "truncating existing feature counts for experiment #{experiment.name}"
          FeatureCount.where(:experiment_id => experiment.id).delete_all
        when 'append'
          # do nothing
        when 'override'
          # delete existing later
        when 'raise'
          puts "Experiment already has #{counts} features with expression. You need to supply an :existing option of 'truncate','append' or 'override' to continue"
          exit 0
        else
          puts "Invalid :existing option found"
          exit 0
        end
      end
      
      idx = 0
      items.each_slice(999) do |batch|
        idx+=999
        batch_ids = []
        batch_hsh = {}
        batch.each do |item|
          batch_ids << item[0]
          batch_hsh[item[0]]=item
        end
        features = Gene.find_all_with_locus_tags(batch_ids)
        feature_ids = features.collect{|f|f.locus_tag.value}
        # check for missing locus
        if feature_ids.size < batch_ids.size
          feature_ids.each do |f|
            unless batch_hsh[f]
              puts "Could not find locus #{locus}"
              raise "Data Error"
            end
          end
        end
        # check for multiple locus
        if feature_ids.size > batch_ids.size
          f_hash={}
          feature_ids.each do |f|
            if f_hash[f]
              puts "There were multiple genes associated with locus(#{f}).
              If you want to load expression for all of them you must supply multiple=>true
              Otherwise, you should supply a taxon version (e.g TAIR10)"
              raise "Data Error"
            end
            f_hash[f]=1
          end
        end
        features.each do |feature|
          if(options[:existing]=='override')
            if f = experiment.features.find(feature.id)
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
        printf "Completed: %5.2f%%\r", (idx.to_f / total_items.to_f)*100
      end
    end#End Transaction
  end#End load method
end
