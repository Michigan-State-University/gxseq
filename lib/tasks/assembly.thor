class Assembly < Thor
  require "#{File.expand_path File.dirname(__FILE__)}/shared_thor"
  include SharedThor
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
    # lookup bioentries
    bioentries = Biosql::Bioentry.where{ assembly_id==my{options[:assembly]} }
    # Set output
    out = File.open(options[:output],'w')
    # Grab all the Genes - use unique l_strand to avoid calling Seqfeature::strand method during output
    genes = Biosql::Feature::Gene.where{bioentry_id.in(my{bioentries})}
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
    assembly = assembly_option_or_ask
    assembly.reindex
  end
end