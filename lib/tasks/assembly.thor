class Assembly < Thor
  ENV['RAILS_ENV'] ||= 'development'
  # return all of the assemblies in the database
  desc 'list','Report name and version of assemblies loaded in the database'
  def list
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    puts "There are #{::Assembly.count} assemblies in the database"
    print_assembly_table
  end
  desc 'dump_gene_coords', 'Dump out the name,start,end,chr, and strand of all genes in an asssembly.'
  method_option :assembly, :aliases => '-a', :required => true, :desc => 'Id for the assembly to export'
  method_option :output, :aliases => '-o', :required => true, :desc => 'Output file name'
  def dump_gene_coords
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # lookup assembly
    assembly = ::Assembly.find(options[:assembly])
    # Set output
    out = File.open(options[:output],'w')
    # Grab all the Genes - use unique l_strand to avoid calling Seqfeature::strand method during output
    genes = Biosql::Feature::Gene.where{bioentry_id.in(my{assembly.bioentries})}
      .joins(:locations,:bioentry,[:qualifiers=>:term])
      .where{qualifiers.term.name=='locus_tag'}
      .select('seqfeature_qualifier_value.value, location.start_pos, location.end_pos, location.strand l_strand, bioentry.accession')
    # Ouput the data
    genes.each do |gene|
      out.puts "#{gene.value},#{gene.start_pos},#{gene.end_pos},#{gene.accession},#{gene.l_strand.to_i}"
    end
  end
  desc 'reindex', 'Reindex an assembly'
  method_option :assembly, :aliases => '-a', :desc => 'Id of the assembly to reindex'
  def reindex
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # lookup assembly
    if(options[:assembly])
      assembly = ::Assembly.find(options[:assembly])
    else
      puts "\nSelect an assembly ID from the list below."
      print_assembly_table
      printf "Assembly ID to reindex:"
      assembly = ::Assembly.find(STDIN.gets.chomp)
    end
    # reindex 
    assembly.reindex
  end
  
  protected
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