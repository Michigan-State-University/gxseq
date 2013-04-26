class Concordance < Thor
  ENV['RAILS_ENV'] ||= 'development'
  desc 'load FILE','Load a new sequence concordance set into the database. FILE is tab delimited, one entry per line: OriginalSequenceID  DatabaseAccession'
  method_option :assembly_id, :aliases => '-a', :required => true, :desc => "Id for the assembly this concordance data describes. Use thor taxonomy:list for help"
  method_option :name, :aliases => '-n', :required => true, :desc => "Name for the new set. Must be unique to the assembly. Use thor concordance:list for help"
  def load(input_file)
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    require 'csv'
    assembly = ::Assembly.find(options[:assembly_id])
    entry_count = assembly.bioentries.count
    # pull in all the data - it might take a while but we want to validate the count
    data = CSV.read(input_file, { :col_sep => "\t" })
    unless data.size == entry_count
      puts "Found #{data.size} entries in file but assembly #{assembly} has #{entry_count} entries"
      return
    end
    ConcordanceSet.transaction do
      concordance_set=ConcordanceSet.create!(
        :name => options[:name],
        :assembly => assembly
      )
      # build a hash for faster lookup
      entry_hash = {}
      puts "Building entry hash"
      progress_bar = ProgressBar.new(data.size)
      assembly.bioentries.select('bioentry_id,accession').each do |entry|
        entry_hash[entry.accession]=entry.bioentry_id
        progress_bar.increment!
      end
      # Insert the new items
      puts "Creating new Concordance Items"
      progress_bar = ProgressBar.new(data.size)
      data.each do |values|
        unless entry_hash[values[1]]
          raise "Unknown entry found #{values}"
        end
        ConcordanceItem.fast_insert(:concordance_set_id => concordance_set.id, :bioentry_id => entry_hash[values[1]],:reference_name => values[0])
        progress_bar.increment!
      end
    end
  end
  
  desc 'list','Print information about concordance sets in the database'
  method_option :assembly_id, :aliases => '-a', :desc => "Only print information for the give assembly id. Use thor taxonomy:list for help"
  def list
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    concords = ConcordanceSet.scoped
    concords.where(:assembly_id => options[:assembly_id]) if options[:assembly_id]
    puts "-\tID\tName\tAssemblyID\tAssemblyName"
    concords.each do |set|
      puts "\t#{set.id}\t#{set.name}\t#{set.assembly_id}\t#{set.assembly.name_with_version}"
    end
  end
end