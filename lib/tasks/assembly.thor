class Assembly < Thor
  ENV['RAILS_ENV'] ||= 'development'
  # return all of the assemblies in the database
  desc 'list','Report name and version of assemblies loaded in the database'
  def list
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    puts "There are #{::Assembly.count} assemblies in the database"
    puts "-\t-\tID\tSpecies\tStrain > Version\tentries"
    ::Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc, version asc').each_with_index do |tv,idx|
      puts "\t#{idx})\t#{tv.id}\t#{tv.species.scientific_name.name}\t#{tv.taxon.scientific_name.name} > #{tv.version}\t#{tv.bioentries.count}"
    end
  end
end