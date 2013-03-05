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
    experiments = Experiment.includes(:assembly).order('experiments.type asc, assemblies.species_id asc, experiments.name asc')
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
  method_option :type, :aliases => '-c',:required => true, :desc => "Provide the Class Name for the Experiment. (#{@@experiments.join(",")})"
  method_option :name, :aliases => '-n',:required => true, :desc  => 'Names must be unique within a taxonomy'
  method_option :description, :aliases => '-d', :type => :string, :desc => 'Description can store any extra metadata for the experiment'
  method_option :assembly_id, :aliases => '-t', :type => :numeric, :required => true, :desc => 'Supply the ID for sequence taxonomy. Use thor taxonomy:list to lookup'
  method_option :data, :aliases => ['-f','--files'], :type => :hash, :required => true, :desc => 'Hash of Assets to load for this experiment; AssetType:path/to/file'
  method_option :username, :default => 'admin', :aliases => '-u', :desc => 'Login name for the experiment owner'
  method_option :group, :aliases => '-g', :desc => "Group name for this experiment"
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
    unless Assembly.find_by_id(options[:assembly_id])
      puts "No taxon with id #{options[:assembly_id]} found. Try: thor taxonomy:list"
    end
    if(options[:group])
      unless group = ::Group.find_by_name(options[:group])
        puts "No Group found with name #{options[:group]}. Try: thor groups:list"
        return
      end
    else
      group = nil
    end
    # Validate assets and build
    assets = []
    options[:data].each do |key,value|
      unless key.constantize.superclass == Asset && File.exists?(value)
        puts "#{key} File Not Found : #{value}"
        return
      end
      #assets << key.constantize.new(:data => File.open(value,'r'))
    end
    
    Experiment.transaction do
      # Create the new experiment
      experiment = options[:type].constantize.create(
        :name => options[:name],
        :description => options[:description],
        :assembly_id => options[:assembly_id],
        :user => owner,
        :group => group
      )
      # Validate experiment
      unless experiment.valid?
        puts experiment.errors.inspect
      end
      # Add the assets
      options[:data].each do |key,value|
        puts "trying #{key} : #{value}"
        #experiment.send("create_#{type.underscore}",{:data => File.open(filename,'r')})
        
        # type.constantize.create(
        #   :data => File.open(filename,'r'),
        #   #:experiment => experiment
        # )
        
        # b = Bam.create(:data => File.open(filename,'r'))
        #b = key.constantize.new(:data => File.open(value,'r'))
        puts b.inspect
      end
      puts b.valid?
      puts b.errors.inspect
      raise "All Done\n\n\n\n"
    end
  end
end