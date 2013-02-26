class Experiments < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  @@experiments = ['ChipChip','ChipSeq','RnaSeq','Variant','ReSeq']
  # List displays experiments in the database
  # Supply -t to filter by experiment type.
  # It is recommended to run this before loading expression to identify the correct experiment name/id
  desc 'list',"Display all of the experiments in the system and their internal ID's\n\tfilter by type with -t: (#{Experiment.select('distinct type').map(&:type).join(',')})"
  method_options %w(verbose -v) => false, %w(type -t) => nil
  def list
    experiments = Experiment.includes(:taxon_version).order('experiments.type asc, taxon_versions.species_id asc, experiments.name asc')
    if(options[:type])
      experiments = experiments.where("type = '#{options[:type]}'")
    end
    exp_length = experiments.max{|e1,e2| e1.name.length <=> e2.name.length}.name.length
    longest_seq = experiments.max{|e1,e2| "#{e1.taxon_version.name} > #{e1.taxon_version.version}".length <=> "#{e2.taxon_version.name} > #{e2.taxon_version.version}".length}
    seq_length = "#{longest_seq.taxon_version.name} > #{longest_seq.taxon_version.version}".length
    printf "%10s %10s %15s %#{exp_length}s %#{seq_length}s\n", '','ID','Type','Name','Sequence'
    (11+11+16+exp_length+seq_length).times do 
      printf "-"
    end
    printf"\n"
    experiments.each_with_index do |e,idx|
      #puts "\t#{idx})\t#{e.id}\t#{e.type}\t#{e.name}\t#{e.taxon_version.name} > #{e.taxon_version.version}\t"
      printf "%10s %10s %15s %#{exp_length}s %#{seq_length}s\n", idx,e.id,e.type,e.name,"#{e.taxon_version.name} > #{e.taxon_version.version}"
    end
  end
  
  desc 'create',"Create a new experiment"
  method_option :type, :aliases => '-t',:required => true, :banner => "Provide the Class Name for the Experiment. (#{@@experiments.join(",")})"
  method_option :name, :aliases => '-n',:required => true, :banner  => 'Names must be unique within a taxonomy'
  method_option :description, :aliases => '-d', :type => :string, :banner => 'Description can store any extra metadata for the experiment'
  method_option :taxon_version_id, :aliases => '-v', :type => :numeric, :required => true, :banner => 'Supply the ID for sequence taxonomy. Use thor taxonomy:list to lookup'
  method_option :data, :aliases => ['-f','--files'], :type => :hash, :required => true, :banner => 'Hash of Assets to load for this experiment. Format is AssetType:filename .. {Bam:file1,BigWig:file2}'
  method_option :username, :default => 'admin', :aliases => '-u', :banner => 'Login name for the experiment owner. Default is: admin'
  def create
    # Validate options
    unless owner = User.find_by_login(options[:username])
      puts "User with login #{options[:username]} not found"
      return
    end
    unless @@experiments.include?(options[:type])
      puts "Invalid Experiment Type: #{options[:type]}. \n Valid options are #{@@experiments.to_sentence}\n"
      return
    end
    unless TaxonVersion.find_by_id(options[:taxon_version_id])
      puts "No taxon with id #{options[:taxon_version_id]} found. Try: thor taxonomy:list"
    end
    # Build the new experiment
    experiment = options[:type].constantize.new(
      :name => options[:name],
      :description => options[:description],
      :taxon_version_id => options[:taxon_version_id],
      :user => owner
    )
    # Validate experiment
    unless experiment.valid?
      puts experiment.errors.inspect
      return
    end
    # Add the assets
    options[:data].each do |type,filename|
      file = File.open(filename)
      experiment.assets.build(
        :type => type,
        :data => file
      )
    end
    # Save
    experiment.save!
  end
end