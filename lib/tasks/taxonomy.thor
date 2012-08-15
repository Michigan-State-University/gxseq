class Db::Taxonomy < Thor
  require 'net/ftp'
  require 'zlib'
  desc 'load',"Load ncbi taxonomy data into the database"
  method_options :directory => "lib/data/taxdata/",:download => false, :verbose => false, :nested_only => false
  def load
    download = options[:download]
    nested_set_only = options[:nested_only]
    verbose = options[:verbose]
    tax_directory = options[:directory]
    base = ActiveRecord::Base
    start_time = Time.now
    
    puts "-v supplied, using verbose output" if verbose
    puts "Loading NCBI Taxonomy"
    if(download)
      # Downloading New taxonomy data
      puts "\t... Downloading taxonomy data" if verbose
      ftp = Net::FTP.new('ftp.ncbi.nlm.nih.gov')
      ftp.login
      ftp.chdir('/pub/taxonomy')
      ftp.getbinaryfile('taxdump.tar.gz',"#{tax_directory}taxdump.tar.gz")
      ftp.close
      puts "\t\t... extracting data" if verbose
      `gunzip -f #{tax_directory}taxdump.tar.gz`
      `cd #{tax_directory}; tar -xf taxdump.tar; rm -f taxdump.tar`
    end
    
    unless(nested_set_only)
      
      # Start the work
      puts "\t... retrieving all taxon nodes in the database\n" if verbose
      old_nodes = base.connection.select_all("SELECT taxon_id, ncbi_taxon_id, parent_taxon_id, node_rank, genetic_code, mito_genetic_code
                                     FROM taxon ORDER BY ncbi_taxon_id")
    
      # try to minimize the parent updates by mapping NCBI
      # taxonIDs to primary keys for the nodes we already have
      id_to_ncbi_map = {}
      ncbi_to_db_id_map = {}
      ncbi_to_data_map = {}
      ncbi_to_parent_ncbi = {}
      old_nodes.each do |node|
       id_to_ncbi_map[node['taxon_id'].to_s]=node['ncbi_taxon_id']
      end
      old_nodes.each do |node|
       ncbi_to_data_map[node['ncbi_taxon_id'].to_s]=[node['ncbi_taxon_id'].to_s,id_to_ncbi_map[node['parent_taxon_id']].to_s,node['node_rank'],node['genetic_code'].to_s,node['mito_genetic_code'].to_s]
      end                                
      old_nodes = nil
      new_nodes = []
      update_nodes = []
      # compare the nodes to our database values, store those needing work
      puts "\t... reading in taxon nodes from nodes.dmp\n" if verbose
      old_node_count = 0
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
           if (old == a)
             # no update necessary
             old_node_count +=1
           else
             # needs update
             update_nodes << a
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
      puts "\t\tnew: #{new_nodes.size}, update: #{update_nodes.size}, delete: #{ncbi_to_data_map.size}, keep: #{old_node_count}" if verbose

      # Insert / Update / Delete nodes
      begin
      Taxon.transaction do
       # insert first ...
       db_time = Time.now.to_s(:db)
       tot = new_nodes.length
       time = Time.now
       last_i = 0
       puts "\t... insert taxon nodes\n" if verbose && tot > 0
       new_nodes.each_with_index do |new_node, i|
         Taxon.fast_insert(
          :ncbi_taxon_id => new_node[0],
          :node_rank => new_node[2],
          :genetic_code => new_node[3],
          :mito_genetic_code => new_node[4])  
          if (verbose && a = log_work(i,last_i,time,tot));(last_i, time = a);end
       end

       # .. update ..
       tot = update_nodes.length
       time = Time.now
       last_i = 0
       puts "\t... update taxon nodes\n" if verbose && tot > 0
       update_nodes.each_with_index do |update_node, i|
         base.connection.execute("UPDATE Taxon 
           SET node_rank='#{update_node[2]}',genetic_code=#{update_node[3]},mito_genetic_code=#{update_node[4]}
           WHERE ncbi_taxon_id=#{update_node[0]}")
         if (verbose && a = log_work(i,last_i,time,tot));(last_i, time = a);end
       end

       # .. get new primary ids ..
       puts "\t... selecting new parent IDs\n" if verbose
       all_nodes = base.connection.select_all("SELECT taxon_id, ncbi_taxon_id
                                               FROM taxon ORDER BY ncbi_taxon_id")
       all_nodes.each do |node|
         ncbi_to_db_id_map[node['ncbi_taxon_id'].to_s]=node['taxon_id']
       end
       all_nodes = nil

       # ... then update parent_ids
       tot = ncbi_to_parent_ncbi.length
       time = Time.now
       last_i = 0
       puts "\t... updating parent IDs\n" if verbose and tot > 0
       ncbi_to_parent_ncbi.each_with_index do |(ncbi_id,ncbi_parent_id),i|
         base.connection.execute("UPDATE Taxon
         SET parent_taxon_id = #{ncbi_to_db_id_map[ncbi_parent_id.to_s]}
         WHERE ncbi_taxon_id = #{ncbi_id}")
         if (verbose && a = log_work(i,last_i,time,tot));(last_i, time = a);end
       end

      end
      rescue
       puts "**Error with Taxon:\n\t#{$!}"
       #exit 0
      end

      # free up some memory
      id_to_ncbi_map = nil
      ncbi_to_data_map = nil
      ncbi_to_parent_ncbi = nil
      update_nodes = nil
      new_nodes = nil
      GC.start

      # Taxon Names
      begin
      TaxonName.transaction do

       puts "\t... reading in taxon names from names.dmp\n" if verbose
       taxon_names_file = File.open(tax_directory+'names.dmp',"r")

       # delete all names for taxon nodes with a NCBI taxonID
       puts "\t... deleting old taxon names\n" if verbose
       base.connection.execute("DELETE FROM TAXON_NAME WHERE taxon_id in (SELECT taxon_id FROM taxon t WHERE t.ncbi_taxon_id IS NOT NULL)")

       # now add the new taxon names from the download
       puts "\t... inserting new taxon names\n" if verbose
       tot = `wc -l #{tax_directory+'names.dmp'}`.split.first.to_i
       time = Time.now
       last_i = 0
       i = 0
       taxon_names_file.each do |line|
         data = line.split(/\s*\|\s*/)
         base.connection.execute("INSERT INTO TAXON_NAME (taxon_id, name, name_class) VALUES (#{ncbi_to_db_id_map[data[0].to_s]}, '#{data[1].gsub(/\'/,"''")}', '#{data[3].gsub(/\'/,"''")}')")
         if (verbose && a = log_work(i,last_i,time,tot,100000));(last_i, time = a);end
         i+=1
       end
       taxon_names_file.close
      end
      rescue
       puts "**Error with Taxon Name:\n\t#{$!}"
       exit 0
      end                         
    end#nested_set_only test
  
    # Rebuilding the Nested Set Tree - using globals for recursive functions - not very clean. TODO: Needs refactor
    @@nested_count = 0
    @@conn = base.connection
    @@taxon_tot = Taxon.count
    @@taxon_count = 0
    @@last_taxon_count=0
    @@time = 0
    @@v = verbose
    @@parent_child_map = Hash.new()
    @@time = Time.now

    base.connection.select_all("SELECT taxon_id, parent_taxon_id FROM taxon ORDER BY ncbi_taxon_id").each do |node|
      @@parent_child_map[node["parent_taxon_id"].to_i] ||= [] 
      (@@parent_child_map[node["parent_taxon_id"].to_i] << node["taxon_id"].to_i) unless (node["parent_taxon_id"].to_i == node["taxon_id"].to_i) # skip if node points at self
    end

    # Nested set calculation
    begin
      puts "\t... rebuilding nested set left/right values\n" if verbose
      # Clear out the current left and right values
      # Can't wrap DDL in Transaction  
      printf "\t\t clearing left values\n" if verbose
      begin
        @@conn.remove_column(:taxon,:left_value)
      rescue
        puts "taxon->left_value column missing o_O why?"
        # it didn't exist?
      end
      @@conn.add_column(:taxon,:left_value,:integer)
      printf "\t\t clearing right values\n" if verbose
      begin
      @@conn.remove_column(:taxon,:right_value)
      rescue
        puts "taxon->right_value column missing o_O why?"
        # it didn't exist?
      end
      @@conn.add_column(:taxon,:right_value,:integer)
      printf "\t\t ..rebuilding\n"
      Taxon.transaction do
        root_id=(TaxonName.find_by_name('root') || Taxon.find(:first, :conditions => "parent_taxon_id == taxon_id OR parent_taxon_id is null")).taxon_id
        update_nested_set(root_id.to_i)
      end
    rescue
      puts "**Error with Nested set:\n\t#{$!}"
      exit 0
    end

    output_time(start_time) 
  end # end load_taxon task
  
   # tell thor to ignore these methods
  protected
  ## OUTPUT HELPER FUNCTIONS 
  # output log data
  def log_work(i,last_i, time, tot, chunk=50000)
    idx = i+1
    if(idx - chunk >= last_i || idx == tot )
      elapsed = (Time.now-time)
      printf("\t\t%d/%d done (in %d secs, %4.1f rows/s)\n", idx,tot,elapsed,(idx-last_i)/elapsed)
      return last_i+chunk, Time.now
    else
      return false
    end
  end
  
  # convert the time taken and output
  def output_time(start_time)
    time_taken = Time.now - start_time
    days = (time_taken / 86400).floor
    remainder = time_taken % (24*60*60)
    puts "Done  ... in #{(days > 0) ? "#{days} days" : ''} #{Time.at(remainder).gmtime.strftime('%R:%S')}"
  end
  
  def update_nested_set(current_id)
    @@taxon_count+=1
    @@nested_count+=1  
    @@conn.execute("Update Taxon SET left_value = #{@@nested_count} where taxon_id = #{current_id}")
    (@@parent_child_map[current_id] || []).each do |child_id|
      update_nested_set(child_id.to_i)
    end  
    @@nested_count+=1
    @@conn.execute("Update Taxon SET right_value = #{@@nested_count} where taxon_id = #{current_id}")
    if (@@v && a = log_work(@@taxon_count,@@last_taxon_count,@@time,@@taxon_tot));(@@last_taxon_count, @@time = a);end
  end
    
end