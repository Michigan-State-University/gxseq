class Sample < Thor
  ENV['RAILS_ENV'] ||= 'development'
  @@samples = ['ChipChip','ChipSeq','RnaSeq','Variant','ReSeq']
  # List displays samples in the database
  # Supply -t to filter by sample type.
  # It is recommended to run this before loading expression to identify the correct sample name/id
  desc 'list',"Display all of the samples in the system and their internal ID's\n\tfilter by type with -t: (#{@@samples.join(',')})"
  method_options %w(verbose -v) => false, %w(type -t) => nil
  def list
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    samples = ::Sample.includes(:assembly).order('samples.type asc, assemblies.species_id asc, samples.name asc')
    if(options[:type])
      samples = samples.where("type = '#{options[:type]}'")
    end
    table = Terminal::Table.new :headings => ['#','ID','Type','Name','Owner','Assembly', 'Concordance'] do |t|
      samples.each_with_index do |s,idx|
        t << [idx, s.id, s.type, s.name, s.user.try(:login)||'-',
          "#{s.assembly.try(:id)||'nil'}::#{s.assembly.try(:name_with_version)}",
          "#{s.concordance_set.try(:id)||'nil'}::#{s.concordance_set.try(:name)}"
        ] 
      end
    end
    puts table
  end
  
  desc 'create',"Create a new sample"
  method_option :type, :aliases => '-t',:required => true, :desc => "Provide the Class Name for the Sample. (#{@@samples.join(",")})"
  method_option :name, :aliases => '-n',:required => true, :desc  => 'Names must be unique within a taxonomy'
  method_option :description, :aliases => '-d', :type => :string, :desc => 'Description can store any extra metadata for the sample'
  method_option :assembly_id, :aliases => '-a', :type => :numeric, :required => true, :desc => 'Supply the ID for sequence taxonomy. Use thor taxonomy:list to lookup'
  method_option :concordance_set_id, :aliases => '-c', :type => :numeric, :required => true, :desc => 'Supply the ID for this samples concordance set. Use thor concordance:list to lookup'
  method_option :data, :aliases => ['-f','--files'], :default => {}, :type => :hash, :desc => 'Hash of Assets to load for this sample: AssetType:path/to/file'
  method_option :traits, :type => :hash, :desc => 'Hash of traits to load for this sample: Key1:Value,Key2:Value'
  method_option :username, :default => 'admin', :aliases => '-u', :desc => 'Login name for the sample owner'
  method_option :group, :aliases => '-g', :desc => "Group name for this sample"
  method_option :local, :default => false, :desc => "Use local path for asset(s) instead of copying data"
  def create
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # Validate options
    unless owner = User.find_by_login(options[:username])
      puts "User with login #{options[:username]} not found; supply a valid login for --username/-u"
      return
    end
    unless @@samples.include?(options[:type])
      puts "Invalid Sample Type: #{options[:type]}. \n Valid options are #{@@samples.to_sentence}\n"
      return
    end
    unless ::Assembly.find_by_id(options[:assembly_id])
      puts "No taxon with id #{options[:assembly_id]} found. Try: thor taxonomy:list"
      return
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
      unless File.exists?(value)
        puts "#{key} File Not Found : #{value}"
        return
      end
    end
    puts "Arguments Look Good. Validating Sample"
    ::Sample.transaction do
      # Create the new sample
      sample = options[:type].constantize.create(
        :name => options[:name],
        :description => options[:description],
        :assembly_id => options[:assembly_id],
        :concordance_set_id => options[:concordance_set_id],
        :user => owner,
        :group => group,
        :traits_attributes => options[:traits].collect{|key,val| {:key=>key,:value=>val} }
      )
      # Validate sample
      unless sample.valid?
        puts sample.errors.inspect
        return
      end
      puts "Sample Looks Good. Adding Assets"
      # Add the assets
      options[:data].each do |key,filename|
        puts "#{key}:#{filename}"
        if options[:local]==true
          Asset.create(
            :type => key,
            :local_path => filename,
            :sample_id => sample.id
          )
        else
          Asset.create(
            :type => key,
            :data => File.open(filename,'r'),
            :sample_id => sample.id
          )
        end
      end
    end
    puts "..Done"
  end
end