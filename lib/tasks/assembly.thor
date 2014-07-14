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
  method_option :assembly, :aliases => '-a', :desc => 'Id for the assembly to export'
  method_option :output, :aliases => '-o', :required => true, :desc => 'Output file name'
  def dump_gene_coords
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    assembly = assembly_option_or_ask
    # lookup bioentries
    bioentries = Biosql::Bioentry.where{ assembly_id==my{assembly.id} }
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
  method_option :all, :default => false, :desc => 'Process all assemblies possibly in parallel'
  method_option :cpu, :default => 1, :aliases => '-c', :desc => 'Number of cpu cores to use in parallel. Ignored without --all'
  def reindex
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    if(options[:all])
      Parallel.each(::Assembly.all.map(&:id), :in_processes => options[:cpu].to_i) do |assembly_id|
        ::Assembly.connection.reconnect!
        ::Assembly.find(assembly_id).reindex
      end
    else
      assembly = assembly_option_or_ask
      assembly.reindex
    end
  end
  
  desc 'index_features', 'Reindex the features in an assembly'
  method_option :assembly, :aliases => '-a', :desc => 'Id of the assembly to reindex'
  method_option :all, :default => false, :desc => 'Process all assemblies possibly in parallel'
  method_option :cpu, :default => 1, :aliases => '-c', :desc => 'Number of cpu cores to use in parallel. Ignored without --all'
  method_option :type, :desc => 'Only index the provided feature type'
  def index_features
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    if(options[:all])
      Parallel.each(::Assembly.all.map(&:id), :in_processes => options[:cpu].to_i) do |assembly_id|
        ::Assembly.connection.reconnect!
        ::Assembly.find(assembly_id).index_features(:type=>options[:type])
      end
    else
      assembly = assembly_option_or_ask
      assembly.index_features(:type=>options[:type])
    end
  end
end