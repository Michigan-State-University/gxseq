class Group < Thor
  ENV['RAILS_ENV'] ||= 'development'
  # return all of the groups in the database
  desc 'list','Report information about groups in the database'
  def list
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # Use explicit top-level namspace because of Thor::Group class
    groups = ::Group.order(:name)
    table = Terminal::Table.new :headings => ['#','Group ID', 'Name', 'Owner', 'Assembly #', 'Sample #'] do |t|
      groups.each_with_index do |g,idx|
        t << [idx, g.id, g.name, "#{g.owner.try(:login)} - #{g.owner.try(:email)}", g.assemblies.count, g.samples.count]
      end
    end
    puts table
  end
end