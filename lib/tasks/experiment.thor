class Experiment < Thor
  ENV['RAILS_ENV'] ||= 'development'
  @@experiments = ['ChipChip','ChipSeq','RnaSeq','Variant','ReSeq']
  # List displays experiments in the database
  # Supply -t to filter by experiment type.
  # It is recommended to run this before loading expression to identify the correct experiment name/id
  desc 'list',"Display all of the experiments in the system and their internal ID's\n\tfilter by type with -t: (#{@@experiments.join(',')})"
  method_options %w(verbose -v) => false, %w(type -t) => nil
  def list
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    experiments = ::Experiment.includes(:assembly).order('experiments.type asc, assemblies.species_id asc, experiments.name asc')
    if(options[:type])
      experiments = experiments.where("type = '#{options[:type]}'")
    end
    exp_length = experiments.max{|e1,e2| e1.name.length <=> e2.name.length}.name.length
    longest_seq = experiments.max{|e1,e2| "#{e1.assembly.name} > #{e1.assembly.version}".length <=> "#{e2.assembly.name} > #{e2.assembly.version}".length}
    seq_length = "#{longest_seq.assembly.name} > #{longest_seq.assembly.version}".length
    printf "%10s %10s %15s %#{exp_length}s %#{seq_length}s\n", '','ID','Type','Name','Sequence'
    (11+11+16+exp_length+seq_length).times do 
      printf "-"
    end
    printf"\n"
    experiments.each_with_index do |e,idx|
      #puts "\t#{idx})\t#{e.id}\t#{e.type}\t#{e.name}\t#{e.assembly.name} > #{e.assembly.version}\t"
      printf "%10s %10s %15s %#{exp_length}s %#{seq_length}s\n", idx,e.id,e.type,e.name,"#{e.assembly.name} > #{e.assembly.version}"
    end
  end
  
  desc 'create',"Create a new experiment"
  method_option :type, :aliases => '-t',:required => true, :desc => "Provide the Class Name for the Experiment. (#{@@experiments.join(",")})"
  method_option :name, :aliases => '-n',:required => true, :desc  => 'Names must be unique within a taxonomy'
  method_option :description, :aliases => '-d', :type => :string, :desc => 'Description can store any extra metadata for the experiment'
  method_option :assembly_id, :aliases => '-a', :type => :numeric, :required => true, :desc => 'Supply the ID for sequence taxonomy. Use thor taxonomy:list to lookup'
  method_option :concordance_set_id, :aliases => '-c', :type => :numeric, :required => true, :desc => 'Supply the ID for this experiments concordance set. Use thor concordance:list to lookup'
  method_option :data, :aliases => ['-f','--files'], :type => :hash, :required => true, :desc => 'Hash of Assets to load for this experiment; AssetType:path/to/file'
  method_option :username, :default => 'admin', :aliases => '-u', :desc => 'Login name for the experiment owner'
  method_option :group, :aliases => '-g', :desc => "Group name for this experiment"
  def create
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # Validate options
    unless owner = User.find_by_login(options[:username])
      puts "User with login #{options[:username]} not found; supply a valid login for --username/-u"
      return
    end
    unless @@experiments.include?(options[:type])
      puts "Invalid Experiment Type: #{options[:type]}. \n Valid options are #{@@experiments.to_sentence}\n"
      return
    end
    unless ::Assembly.find_by_id(options[:assembly_id])
      puts "No taxon with id #{options[:assembly_id]} found. Try: thor taxonomy:list"
    end
    unless group = ::Group.find_by_name(options[:group])
      puts "No Group found with name #{options[:group]}. Try: thor group:list"
      return
    end
    unless ConcordanceSet.find_by_id(options[:concordance_set_id])
      puts "No ConcordanceSet with id #{options[:concordance_set_id]}. Try: thor concordance:list"
      return
    end
    # Validate assets and build
    options[:data].each do |key,value|
      unless key.constantize.superclass == Asset && File.exists?(value)
        puts "#{key} File Not Found : #{value}"
        return
      end
    end
    puts "Arguments Look Good. Validating Experiment"
    ::Experiment.transaction do
      # Create the new experiment
      experiment = options[:type].constantize.create(
        :name => options[:name],
        :description => options[:description],
        :assembly_id => options[:assembly_id],
        :concordance_set_id => options[:concordance_set_id],
        :user => owner,
        :group => group
      )
      # Validate experiment
      unless experiment.valid?
        puts experiment.errors.inspect
        return
      end
      puts "Experiment Looks Good. Adding Assets"
      # Add the assets
      options[:data].each do |key,filename|
        puts "#{key}:#{filename}"
        Asset.create(
          :type => key,
          :data => File.open(filename,'r'),
          :experiment_id => experiment.id
        )
      end
    end
    puts "..Done"
  end
end