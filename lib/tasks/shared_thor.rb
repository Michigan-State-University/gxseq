module SharedThor
  require 'terminal-table'
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
    return if assemblies.empty?
    table = Terminal::Table.new :headings => ['ID', 'Species', 'Strain > Version', 'Sequence #'] do |t|
      assemblies.each_with_index do |asm,idx|
        t << [asm.id, asm.species_name, asm.name_with_version, asm.bioentries.count] 
      end
    end
    puts table
  end
end