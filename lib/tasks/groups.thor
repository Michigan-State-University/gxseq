class Groups < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  # return all of the assemblies in the database
  desc 'list','Report information about groups in the database'
  def list
    # Use explicit top-level namspace because of Thor::Group class
    groups = ::Group.all
    max_name_count = groups.map{|g|g.name.length}.max + 3
    puts "There are #{groups.length} groups in the database"
    puts "-\t-\tID\tName#{' '*(max_name_count-4)}Owner\temail\tAssemblyCount\tSampleCount"
    groups.each_with_index do |group,idx|
      puts "\t#{idx})\t#{group.id}\t#{group.name}#{' '*(max_name_count-group.name.length)}#{group.owner.login}\t#{group.owner.email}\t#{group.assemblies.count}\t#{group.experiments.count}"
    end
  end
end