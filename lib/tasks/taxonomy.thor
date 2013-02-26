class Taxonomy < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
  require 'net/ftp'
  require 'zlib'
  require 'progress_bar'
  #TODO: Update thor task help docs, Need more descriptive output
  desc 'load',"Load ncbi taxonomy data into the database"
  method_options :directory => "lib/data/taxdata/",:download => true, :verbose => false, :nested_set => false, :check_count => false
  def load
    download = options[:download]
    nested_set = options[:nested_set]
    verbose = options[:verbose]
    tax_directory = options[:directory]
    check_counts = options[:check_count]
    base = ActiveRecord::Base
    start_time = Time.now
    puts "..using verbose output" if verbose
    # Nested Set calculation
    if(nested_set)
      puts "Rebuilding nested_set"
      Taxon.rebuild_nested_set(verbose)
      exit 0
    end
    puts "Loading NCBI Taxonomy"
    # Downloading New taxonomy data
    if(download)
      puts "\t... Downloading taxonomy data" if verbose
      ftp = Net::FTP.new('ftp.ncbi.nlm.nih.gov')
      ftp.passive = true
      ftp.login
      ftp.chdir('/pub/taxonomy')
      ftp.getbinaryfile('taxdump.tar.gz',"#{tax_directory}taxdump.tar.gz")
      ftp.close
      puts "\t\t... extracting data" if verbose
      `gunzip -f #{tax_directory}taxdump.tar.gz`
      `cd #{tax_directory}; tar -xf taxdump.tar; rm -f taxdump.tar`
    end
    # Start the work
    puts "\t... retrieving all taxon nodes in the database\n" if verbose
    old_nodes = base.connection.select_all("SELECT taxon_id, ncbi_taxon_id, parent_taxon_id, node_rank, genetic_code, mito_genetic_code
      FROM taxon WHERE non_ncbi = 0 ORDER BY ncbi_taxon_id")
    # try to minimize the parent updates by mapping NCBI taxonIDs to primary keys for the nodes we already have
    puts "\t... mapping primary ids\n" if verbose
    id_to_ncbi_map = {}
    ncbi_to_db_id_map = {}
    ncbi_to_data_map = {}
    ncbi_to_parent_ncbi = {}
    needs_taxon_names_map = {}
    # database to ncbi map - build this first to allow lookup in second iteration
    old_nodes.each do |node|
      id_to_ncbi_map[node['taxon_id'].to_s]=node['ncbi_taxon_id']
    end
    old_nodes.each do |node|
      # NCBI ID -> Data(ncbi_id,parent_ncbi_id,node_rank,genetic_code,mito_genetic_code,taxon_id)
      # this mapping is a working copy, it will only contain data to be removed after parsing the file
      ncbi_to_data_map[node['ncbi_taxon_id'].to_s]=[node['ncbi_taxon_id'].to_s,id_to_ncbi_map[node['parent_taxon_id'].to_s].to_s,node['node_rank'],node['genetic_code'].to_s,node['mito_genetic_code'].to_s,node['taxon_id']]
      # ncbi to database map
      ncbi_to_db_id_map[node['ncbi_taxon_id'].to_s]=node['taxon_id'].to_i
    end
    # free up this memory
    old_nodes = nil
    new_nodes = []
    update_nodes = []
    old_node_count = 0
    # compare the nodes to our database values, store those needing work
    puts "\t... reading in taxon nodes from nodes.dmp\n" if verbose
    File.open(tax_directory+'nodes.dmp',"r"){|file|
     file.each do |line|
       data = line.split(/\s*\|\s*/)
       # tax_id, parent_tax_id, rank, genetic_code, mito_genetic_code
       a = [data[0],data[1],data[2],data[6],data[8]]
       #skip if the file data is invalid
       next if a.compact.size < 5
       # if we have the ncbi_id_stored
       if(old = ncbi_to_data_map[a[0]])      
         # if our data and the ncbi data matches
         if (old[0,5] == a)
           # no update necessary
           old_node_count +=1
         else
           # needs update - add current primary key to data
           update_nodes << a.push(old[5])
           ncbi_to_parent_ncbi[a[0]]=a[1]
         end      
         # done with this data remove from hash
         ncbi_to_data_map.delete(a[0])
       else
         # new ncbi_id
         new_nodes << a
         ncbi_to_parent_ncbi[a[0]]=a[1]
       end
     end
    }
    puts "\t\tnew: #{new_nodes.size}, update: #{update_nodes.size}, delete: #{ncbi_to_data_map.length}, keep: #{old_node_count}" if verbose || check_counts
    if(check_counts)
      
      exit 0
    end
    # Taxon Insert / Update / Delete
    begin
    Taxon.transaction do
      db_time = Time.now.to_s(:db)
      node_ids_needing_parent_update = []
      # insert first ...
      if(new_nodes.length > 0)
        puts "\t... insert taxon nodes\n" if verbose
        progress_bar = ProgressBar.new(new_nodes.length)
        new_nodes.each_slice(100) do |node_batch|
          node_batch.each do |new_node|
            # Try to find the database id of the parent_node
            parent_taxon_id = ncbi_to_db_id_map[ new_node[1] ]
            # Insert the new data and save id
            ncbi_to_db_id_map[new_node[0]] = Taxon.fast_insert(
              :ncbi_taxon_id => new_node[0],
              :parent_taxon_id => parent_taxon_id,
              :node_rank => new_node[2],
              :genetic_code => new_node[3],
              :mito_genetic_code => new_node[4],
              :created_at => db_time,
              :updated_at => db_time
            )
            # if the parent hasn't been created yet, save this node for later
            unless parent_taxon_id
              node_ids_needing_parent_update << [ncbi_to_db_id_map[new_node[0]],new_node[1]]
            end
            # save ncbi id for taxon name load
            needs_taxon_names_map[new_node[0]] = 1
          end
          progress_bar.increment!(node_batch.length)
        end
      end
      # add any temporarily missing parent ids
      if(node_ids_needing_parent_update.length > 0)
        node_ids_needing_parent_update.each_slice(100) do |id_batch|
          id_batch.each do |node_id,parent_ncbi_id|
            base.connection.execute("UPDATE Taxon
            SET parent_taxon_id = #{ncbi_to_db_id_map[parent_ncbi_id.to_s]}
            WHERE taxon_id = #{node_id}")
          end
        end
      end
      # update nodes
      if(update_nodes.length > 0)
        puts "\n\t... update taxon nodes\n" if verbose
        progress_bar = ProgressBar.new(update_nodes.length)
        update_nodes.each_slice(100) do |update_batch|
          update_batch.each do |update_node|
            # update the taxon information
            base.connection.execute("UPDATE Taxon
              SET node_rank='#{update_node[2]}',genetic_code='#{update_node[3]}',mito_genetic_code='#{update_node[4]}',
              parent_taxon_id=#{ncbi_to_db_id_map[update_node[1]]}, updated_at='#{db_time}'
              WHERE ncbi_taxon_id=#{update_node[0]}")
            # remove any existing taxon_name information
            base.connection.execute("DELETE FROM TAXON_NAME WHERE taxon_id=#{update_node[5]}")
            # save ncbi id for taxon name load
            needs_taxon_names_map[update_node[0]] = 1
          end
          progress_bar.increment!(update_batch.length)
        end
      end
      # delete any extras - check to make sure no deleted nodes are in use as taxon or species first
      t_versions = {}
      s_versions = {}
      TaxonVersion.all.each do |tv| 
        t_versions[tv.taxon_id]=tv
        s_versions[tv.species_id]=tv
      end
      if(ncbi_to_data_map.length > 0)
        puts "\n\t... delete taxon nodes\n" if verbose
        progress_bar = ProgressBar.new(ncbi_to_data_map.length)
        ncbi_to_data_map.each_slice(100) do |delete_batch|
          delete_batch.each do |delete_node,data|
            db_taxon_id = ncbi_to_db_id_map[delete_node]
            if (t = t_versions[db_taxon_id]) || (t = s_versions[db_taxon_id])
              puts "In use Taxon slated for removal\n\t#{t.inspect}\n\tId to remove:#{db_taxon_id}"
              response = ask "Type 'yes' to remove, anything else to skip:"
              next unless response == 'yes'
            end
            base.connection.execute("DELETE FROM Taxon where ncbi_taxon_id=#{delete_node}")
            base.connection.execute("DELETE FROM TaxonName where taxon_id=#{db_taxon_id}")
          end
          progress_bar.increment!(delete_batch.length)
        end
      end
      # Taxon Names
      # parse out any names that need to be inserted / updated
      puts "\t... reading in taxon names from names.dmp\n" if verbose
      taxon_name_data = []
      taxon_names_file = File.open(tax_directory+'names.dmp',"r")
      taxon_names_file.each do |line|
        data = line.split(/\s*\|\s*/)
        taxon_name_data << data if needs_taxon_names_map[data[0]]
      end
      taxon_names_file.close
      # now add the new taxon names from the download
      puts "\t... inserting new taxon names\n" if verbose
      progress_bar = ProgressBar.new(taxon_name_data.length)
      unique_taxon_name = ''
      taxon_name_data.each_slice(100) do |taxon_name_batch|
        taxon_name_batch.each do |taxon_name|
          # If a unique name is present use it otherwise just use the name, convert single quotes to double for direct sql insert
          unique_taxon_name = ( taxon_name[2].strip.empty? ? taxon_name[1].gsub(/\'/,"''") : taxon_name[2].gsub(/\'/,"''") )
          base.connection.execute("INSERT INTO TAXON_NAME (taxon_id, name, name_class,created_at,updated_at) VALUES (#{ncbi_to_db_id_map[taxon_name[0].to_s]}, '#{unique_taxon_name}', '#{taxon_name[3].gsub(/\'/,"''")}','#{db_time}','#{db_time}')")
        end
        progress_bar.increment!(taxon_name_batch.length)
      end
    end
    rescue
     puts "**Error:\n\t#{$!}"
     #exit 0
    end
    # convert the time taken and output
    time_taken = Time.now - start_time
    days = (time_taken / 86400).floor
    remainder = time_taken % (24*60*60)
    puts "Done  ... in #{(days > 0) ? "#{days} days" : ''} #{Time.at(remainder).gmtime.strftime('%R:%S')}"
  end # end load_taxon task
  
  # return all of the taxonomy version in the database
  desc 'list','Report name and version of taxonomy for sequences loaded in the database'
  def list
    puts "There are #{TaxonVersion.count} taxonomies used in the database"
    puts "-\t-\tID\tSpecies\tStrain > Version\tentries"
    TaxonVersion.includes(:taxon => :scientific_name).order('taxon_name.name asc, version asc').each_with_index do |tv,idx|
      puts "\t#{idx})\t#{tv.id}\t#{tv.species.scientific_name.name}\t#{tv.taxon.scientific_name.name} > #{tv.version}\t#{tv.bioentries.count}"
    end
  end
  
  # The Find method performs a search against the database retrieving and displaying all taxon names that match.
  # It is recommended to run this before loading sequence to find the correct species and varietas names.
  desc 'find QUERY','Search the taxonomy tree to find matching entries. Helpful to verify taxonomy name before loading sequence'
  def find(query)
    puts "-\t-\tTaxonID\tRank\tName\tName Class"
    TaxonName.includes(:taxon).where("upper(name) like ? and taxon.taxon_id > 0","%#{query.upcase}%").order('taxon.node_rank asc, name asc').each_with_index do |taxon_name,idx|
      puts "\t#{idx})\t#{taxon_name.taxon.id}\t#{taxon_name.taxon.node_rank}\t#{taxon_name.name}\t#{taxon_name.name_class}"
    end
  end

end
