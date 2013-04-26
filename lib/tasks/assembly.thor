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
  desc 'dump_gene_coords', 'Dump out the name,start,end,chr, and strand of all genes in an asssembly.'
  method_option :assembly, :aliases => '-a', :required => true, :desc => 'Id for the assembly to export'
  method_option :output, :aliases => '-o', :required => true, :desc => 'Output file name'
  def dump_gene_coords
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # lookup assembly
    assembly = ::Assembly.find(options[:assembly])
    # Set output
    out = File.open(options[:output],'w')
    # Grab all the Genes
    genes = Biosql::Feature::Gene.where{bioentry_id.in(my{assembly.bioentries})}
      .joins(:locations,:bioentry,[:qualifiers=>:term])
      .where{qualifiers.term.name=='locus_tag'}
      .select('seqfeature_qualifier_value.value, location.start_pos, location.end_pos, location.strand, bioentry.accession')
    # Ouput the data
    genes.each do |gene|
      out.puts "#{gene.value},#{gene.start_pos},#{gene.end_pos},#{gene.accession},#{gene.strand.to_i}"
    end
  end
end