module SharedThor
  protected
  def assembly_option_or_ask
    # lookup assembly
    if(options[:assembly])
      assembly = ::Assembly.find(options[:assembly])
    else
      puts "\nSelect an assembly ID from the list below."
      print_assembly_table
      printf "Assembly ID:"
      assembly = ::Assembly.find(STDIN.gets.chomp)
    end
  end
  
  def print_assembly_table
    assemblies = ::Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc, version asc')
    # get max character counts
    species_length = assemblies.max{|a1,a2| a1.species_name.length <=> a2.species_name.length}.species_name.length
    seq_length = assemblies.max{|a1,a2| a1.name_with_version.length <=> a2.name_with_version.length}.name_with_version.length
    # print the header
    printf "%10s %10s %#{species_length}s %#{seq_length}s %10s\n",'','ID','Species','Strain > Version','Entries'
    (33+species_length+seq_length).times do 
      printf "-"
    end
    printf"\n"
    assemblies.each_with_index do |tv,idx|
      printf "%10s %10s %#{species_length}s %#{seq_length}s %10s\n", '', tv.id, tv.species_name, tv.name_with_version, tv.bioentries.count
    end
  end
end