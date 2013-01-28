class BioentriesController < ApplicationController
  authorize_resource :except => [:metadata, :track_data]
  def index
    # Defaults
    params[:page] ||=1
    params[:c]||='taxon_version_name'
    # Filter setup
    @taxon_versions = TaxonVersion.accessible_by(current_ability).includes(:taxon => :scientific_name).order('taxon_name.name')
    @taxon_versions = @taxon_versions.where("taxon_versions.type = ?",params[:taxon_type]) unless params[:taxon_type].blank?
    @biodatabases = Biodatabase.order('name')
    # Format
    respond_to do |wants|
      wants.html {
        ## Search block
        @search = base_search do |s|
          s.paginate(:page => params[:page], :per_page => 20)
        end
      }
      wants.fasta {
        ## Search block - hack to get around forced paging, 
        search = base_search do |s|
          s.paginate(:page => 1, :per_page => Bioentry.count)
        end
        # set disposition to attachment
        headers["Content-disposition"] = 'attachment;'
        # use custom proc for response body
        # NOTE: change to streaming Enumerator for rails 3.2
        self.response_body = proc {|resp, out|
          search.results.each do |entry|
            # write the entry header
            out.write entry.fasta_header
            # write each line of sequence
            entry.biosequence.yield_fasta do |output_part|
              out.write output_part
            end
          end
        }
      }
      wants.genbank {
        ## Search block
        search = base_search do
          s.paginate(:page => 1, :per_page => Bioentry.count)
        end
        # set disposition to attachment
        headers["Content-disposition"] = 'attachment;'
        self.response_body = proc {|resp, out|
          search.results.each do |entry|
            # write the entry header
            out.write entry.genbank_header
            # process the features in batches (for manageable includes)
            entry.seqfeatures.includes{[type_term,qualifiers.term,locations]}.find_in_batches(:batch_size => 500) do |feature_batch|
              # write the feature and qualifiers
              feature_batch.each do |feature|
                out.write feature.to_genbank(false)
              end
            end
            # write each line of sequence
            entry.biosequence.yield_genbank do |output_part|
              out.write output_part
            end
            # end the entry
            out.write "//\n"
          end
        }
      }
      wants.json {
        search = base_search do |s|
          s.paginate(:page => params[:page], :per_page => params[:limit])
        end
        data=[]
        search.results.each do |entry|
         # b = Bioentry.find(entry.id, :include => [:taxon_version,[:source_features => [:qualifiers => :term]]] )
          #add the datapoint
          data.push( {
            :id => entry.id,
            :name => entry.display_name,
            :accession => entry.accession,
            :reload_url => (params[:reload_url]||bioentries_path)
          })
        end
        # render the match
        render :json  => {
          :success => true,
          :count => search.results.total_entries,
          :rows => data
        }
      }
    end
  end
  
  def new
  end
  
  def create
  end
  
  def show
    @bioentry = Bioentry.find(params[:id])
    authorize! :read, @bioentry
    # config params
    # the feature_id will be used to lookup the given feature on load. It will NOT set the position.
    @feature_id = params[:feature_id]
    @gene_id = params[:gene_id]
    # position
    @position = params[:pos]
    # zoom
    @bases = params[:b]
    @pixels = params[:p]
    # tracks will be activated by type or id if no layout is provided
    @tracks_param = params[:tracks]
    
    ## get layout id
    if(params[:default])
      current_user.preferred_track_layout=nil, @bioentry
      current_user.save!
      layout_id = nil
    elsif params[:layout_id]
      layout_id = params[:layout_id]
      current_user.preferred_track_layout=layout_id, @bioentry
      current_user.save! 
    else
      layout_id = current_user.preferred_track_layout(@bioentry) unless @tracks_param
    end
    
    # if we have a layout_id find the layout and set the active tracks
    # otherwise check the parameters for track ids
    # fallback on default tracks
    if(layout_id)
      begin
        @layout = TrackLayout.find(layout_id)
        @active_tracks = @layout.active_tracks
      rescue
        @layout = nil
      end
    else
      @param_track_ids = []
      if(@tracks_param && @tracks_param.is_a?(Array))
        @tracks_param.each do |track|
          if(track.is_a?(String) && @bioentry.respond_to?(track) && @bioentry.send(track))
            @param_track_ids << @bioentry.send(track).id
          elsif(track.respond_to?('to_i') && @bioentry.tracks.find(track.to_i))
            @param_track_ids << @bioentry.tracks.find(track).id
          end
        end
      end
      unless(@param_track_ids.empty?)
        # use parameter tracks
        @active_tracks = @param_track_ids.to_json
      else
        # use default
        @active_tracks =[@bioentry.six_frame_track.id,@bioentry.models_track.id].to_json
      end
    end
    render :layout => 'sequence_viewer'
  end
  
  def edit
    @bioentry = Bioentry.find(params[:id])
    authorize! :update, @bioentry
  end

  def update
    @bioentry = Bioentry.find(params[:id])
    authorize! :update, @bioentry
    respond_to do |wants|
      if @bioentry.update_attributes(params[:bioentry])
        flash[:notice] = 'Bioentry was successfully updated.'
        wants.html { redirect_to(@bioentry) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end
  
  # SV App Data - syndication response
  # Expects: bioentry_id
  # Returns: JSON hash of service provider and sequence selection data
  def metadata
    # setup
    jrws = JSON.parse(params[:jrws])
    param = jrws['param']
    bioentry_id = param['bioentry']
    bioentries = []
    species_array = []
    versions = []
    taxons = []
    use_bioentry_search = false
    bioentry = Bioentry.find(bioentry_id)
    # auth
    authorize! :read, bioentry
    bioentry_tv = bioentry.taxon_version
    bioentry_sp = bioentry_tv.species
    taxon_versions = bioentry_sp.species_taxon_versions.accessible_by(current_ability).includes(:taxon)
    # Collect Species
    Taxon.with_species_taxon_versions.accessible_by(current_ability).each do |taxon|
      species_array.push({
        :id => taxon.species_taxon_versions.first.bioentries.first.try(:id),
        :name => taxon.name
      })
    end
    # Collect Strain/Variety/SubTaxon
    taxon_versions.map(&:taxon).uniq.each do |taxon_strain|
      taxons.push({
        :id => taxon_strain.taxon_versions.accessible_by(current_ability).first.bioentries.first.try(:id),
        :name => (taxon_strain == bioentry_sp) ? "Generic Strain" : taxon_strain.name
      })
    end
    # Collect Version
    taxon_versions.each do |taxon_version|
      versions.push({
        :id => taxon_version.bioentries.first.try(:id),
        :name => taxon_version.version
      })
    end
    # Using search form unless there is only 1 sequence
    if bioentry_tv.bioentries.count == 1
      bioentry_tv.bioentries.includes(:source_features => :qualifiers).each do |entry|
        bioentries.push({
          :id => entry.id,
          :accession => entry.accession,
          :name => entry.display_name
        })
      end
    else
      use_bioentry_search = true
    end

    # TODO: Remove romans plugin - only use case (sorting) removed by text search addition
    # Sort the sequence list, this converts everything to integer, Long strings i.e mitochondria/plasmid will be sorted arbitrarily
    # bioentries.sort!{|a,b| (a[:name].is_roman_numeral? ? a[:name].to_i_roman : a[:name].to_i) <=> (b[:name].is_roman_numeral? ? b[:name].to_i_roman : b[:name].to_i) }

    # JSON Response
    render :json  => {
      :success => true, 
      :data => {
        :institution => {
          :name => 'Great Lakes Bioenergy Research Center',
          :url => 'http://www.glbrc.org',
          :logo => "http://glbrc.org/sites/all/themes/gbif/images/GLBRC_horz_cmyk_small.jpg"
        },
        :engineer => {
          :name => 'Nicholas A. Thrower', 
          :email => 'throwern@msu.edu'
        },
        :service => {
          :title => bioentry_sp.name,
          :copyright => 'Copyright 2012 GLBRC', 
          :license => 'http://creativecommons.org',
          :version => '1.0',
          :entry_url => bioentries_path,
          :description => ''
        },
        :species => {
          :data => species_array, 
          :selected => bioentry_sp.name
        },
        :taxons => {
          :data => taxons, 
          :selected => (bioentry_tv.taxon == bioentry_sp ? "Generic Strain" : bioentry_tv.name)
        },
        :versions => {
          :data => versions,
          :selected => bioentry_tv.version
        },
        :entries => {
          :data => bioentries, 
          :selected => bioentry.generic_label,
          :use_search => use_bioentry_search,
          :search_url => bioentries_path(:format => :json),
          :taxon_version_id => bioentry_tv.id
        },
        :entry => {
          :accession => bioentry.accession,
          :accession_link => ACCESSION_LINK,
          :size => (bioentry.length rescue 1000),
        }
      }
    }
  end
  
  
  # Six Frame Track data
  # NOTE: maybe sequence track should move from bioentries to biosequence
  def track_data
    unless params[:jrws].blank?
       jrws = JSON.parse(params[:jrws])
       param = jrws['param']
       case jrws['method']
       when 'syndicate'
         # TODO: fill in bioentry track syndication data
          render :json  => {
             :success => true,
             :data => {
                :institution => {
                   :name => "GLBRC",
                   :url => "http:\/\/www.glbrc.org\/",
                   :logo => ""
                },
                :engineer => {
                   :name => "Nick Thrower",
                   :email => "throwern@msu.edu"
                },
                :service => {
                   :title => "Genome Sequence",
                   :species => "",
                   :access => "",
                   :version => "",
                   :format => "",
                   :server => "",
                   :description => ""
                }
             }
          }
       when 'sequence'
         bioentry_id = param['bioentry']
         bioentry = Bioentry.find(bioentry_id)
         authorize! :read, bioentry
         biosequence = Biosequence.find_by_bioentry_id(bioentry_id)
         render :partial => "biosequence/show", :locals => {:biosequence => biosequence, :start => param['left'], :stop => param['right']}
       when 'range'
         bioentry_id = param['bioentry']
         bioentry = Bioentry.find(bioentry_id)
         authorize! :read, bioentry
         left = param['left']
         right = param['right']
         length = right - left +1
         if(param['bases']==1 && param['pixels']>1)
           bioseq = Biosequence.find_by_bioentry_id(bioentry_id.to_i)
           sequence = bioseq.seq[ left, length ]
           data = bioseq.get_six_frames(left, right)
           render :json => {
              :success => true,
                :data => {
                  :sequence  => {
                    :seq  =>[# [id,x,w,sequence]
                      [left+1, left+1, length, sequence]
                    ],
                  },
                :sixframe => {# [id,x,w,sequence,frame#,offset]..]
                   :frame => data     
                }
              }
           }            
         elsif(param['bases'] < 10 )
           bioseq = Biosequence.find_by_bioentry_id(bioentry_id.to_i)
           sequence = bioseq.seq[ left, length ]
           data = bioseq.get_six_frames(left, right)
           render :json => {
              :success => true,
                :data => {
                  :sequence  => {
                    :seq  =>[# [id,x,w,sequence]
                      [left+1, left+1, length, sequence]
                    ],
                    :gc_content => [# [id,x,w,sequence]
                        [left+1, left + 1, length, bioseq.get_gc_content(left,length,param['bases'])]
                     ]
                  },
                :sixframe => {# [id,x,w,sequence,frame#,offset]..]
                   :frame => data     
                }
              }
           }
         elsif(param['bases']>=10)
           bioseq = Biosequence.where(:bioentry_id => bioentry_id.to_i).select(:id,:version).first
           data =  bioseq.get_gc_content(left,length,param['bases'])
          render :json => {
             :success => true,
               :data => {
                 :sequence  => {
                   :gc_content => [# [id,x,w,sequence]
                       [left+1, left + 1, length, data] 
                    ]
                 },
             }
          }
         else
           render :json  => {
             :success  => false
           }
         end
       end
     else
       render :json => {
          :succes => false
       }
     end   
  end
  
  protected
  # Base search block
  def base_search
    order_d = (params[:d]=='down' ? 'desc' : 'asc')
    params[:keywords] = params[:query] if params[:query]
    # Find minimum set of id ranges accessible by current user
    authorized_id_set = Bioentry.accessible_by(current_ability).select_ids.to_ranges
    # Set to -1 if no items are found. This will force empty search results
    authorized_id_set=[-1] if authorized_id_set.empty?
    # Begin block
    @search = Bioentry.search do |s|
      # Text Keywords
      if params[:keywords]
        s.keywords params[:keywords], :fields => [:accession_text,:description_text,:sequence_type_text,:sequence_name_text,:species_name_text,:taxon_version_name_text], :highlight => true
      end
      # Auth      
      s.any_of do |any_s|
        authorized_id_set.each do |id_range|
          any_s.with :id, id_range
        end
      end
      # Filters
      s.with :taxon_version_id, params[:taxon_version] unless params[:taxon_version].blank?
      s.with :biodatabase_id, params[:biodatabase] unless params[:biodatabase].blank?
      s.with :taxon_version_type, params[:taxon_type] unless params[:taxon_type].blank?
      # Sort
      s.order_by params[:c].to_sym, order_d
      # Paging + extras
      yield(s)
    end
  end
  
end
