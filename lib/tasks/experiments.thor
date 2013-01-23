class Experiments < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  # List search and displays experiments in the database
  # Supply -t to filter by experiment type.
  # It is recommended to run this before loading expression to identify the correct experiment name/id
  desc 'list',"Display all of the experiments in the system and their internal ID's\n\tfilter by type with -t: (#{Experiment.select('distinct type').map(&:type).join(',')})"
  method_options %w(verbose -v) => false, %w(type -t) => nil
  def list
    experiments = Experiment.includes(:taxon_version).order('type asc, taxon_versions.name asc, experiments.name asc')
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
end