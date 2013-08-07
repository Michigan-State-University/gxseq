class Feature < Thor
  require "#{File.expand_path File.dirname(__FILE__)}/shared_thor"
  include SharedThor
  ENV['RAILS_ENV'] ||= 'development'
  desc 'dump','Dump Features from the database '
  method_option :assembly, :aliases => '-a', :desc => 'Id of the assembly to reindex'
  method_option :output, :aliases => '-o', :desc => 'Output file name'
  method_option :type, :aliases => '-f', :default =>  'Gene'
  method_option :per_page, :aliases => '-p', :default => 500
  method_option :locus_list, :aliases => '-l', :type => :array, :desc => 'List of locus tags to download.. -l one two three ...'
  def dump
    require File.expand_path("#{File.expand_path File.dirname(__FILE__)}/../../config/environment.rb")
    # lookup assembly
    fileout = options[:output] ? File.open(options[:output],'w') : STDOUT
    logout = STDERR
    assembly = assembly_option_or_ask
    # setup header
    fileout.printf("Id,")
    anno_terms = []
    blast_terms = []
    Biosql::Term.select('distinct term.term_id, term.name')
      .joins(:ontology,[:qualifiers => [:seqfeature => :bioentry]])
      .where{ bioentry.assembly_id == my{assembly.id} }.each do |term|
        anno_terms << term
        fileout.printf("#{term.name.humanize},")
      end
    assembly.blast_runs.each do |run|
      blast_terms<<"blast_#{run.id}"
      fileout.printf("#{run.name} Def, #{run.name} ID,")
    end
    fileout.printf("Length\n")
    
    assembly.iterate_features(options) do |search|
      search.hits.each do |hit|
        fileout.printf("#{hit.stored(:id)},")
        anno_terms.each do |term|
          if(hit.stored((term.name+'_text').to_sym))
            fileout.printf("\"#{hit.stored((term.name+'_text').to_sym).try(:join,'; ')}\",")
          else
            fileout.printf("\"#{hit.stored("term_#{term.id}_text".to_sym).try(:join,'; ')}\",")
          end
        end
        blast_terms.each do |term|
          fileout.printf("\"#{hit.stored(("#{term}_text").to_sym).try(:first)}\",#{hit.stored(:blast_acc,term)},")
        end
        fileout.printf("#{hit.stored(:end_pos)-hit.stored(:start_pos)}\n")
      end
    end
  end
end