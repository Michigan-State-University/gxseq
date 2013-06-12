class Biosql::BioentriesController < ApplicationController
  authorize_resource :except => [:metadata, :track_data], :class => "Biosql::Bioentry"
  def index
    # Defaults
    params[:page] ||=1
    params[:c]||='assembly_name'
    # Filter setup
    @assemblies = Assembly.accessible_by(current_ability).includes(:taxon => :scientific_name).order('taxon_name.name')
    @assemblies = @assemblies.where("assemblies.type = ?",params[:taxon_type]) unless params[:taxon_type].blank?
    @biodatabases = Biosql::Biodatabase.order('name')
    # Format
    respond_to do |wants|
      wants.html {
        ## Search block
        @search = base_search do |s|
          s.paginate(:page => params[:page], :per_page => 20)
        end
      }
      wants.fasta {
        # FIXME: Large chromosome is chopping off last line of sequence
        ## Search block - hack to get around forced paging, 
        fasta_search = base_search do |s|
          s.paginate(:page => 1, :per_page => Biosql::Bioentry.count)
        end
        # set disposition to attachment
        headers["Content-disposition"] = 'attachment;'
        # use custom proc for response body
        # NOTE: change to streaming Enumerator for rails 3.2
        self.response_body = proc {|resp, out|
          fasta_search.hits.each_slice(100) do |hits|
            Biosql::Bioentry.where(:bioentry_id => hits.map{|h| h.stored(:id)}).includes(:biosequence_without_seq).each do |entry|
              # write the entry header
              out.write entry.fasta_header
              # write each line of sequence
              entry.biosequence.yield_fasta do |output_part|
                out.write output_part
              end
            end
          end
        }
      }
      wants.genbank {
        ## Search block
        genbank_search = base_search do |s|
          s.paginate(:page => 1, :per_page => Biosql::Bioentry.count)
        end
        # set disposition to attachment
        headers["Content-disposition"] = 'attachment;'
        # use custom proc for response body
        self.response_body = proc {|resp, out|
          genbank_search.hits.each_slice(100) do |hits|
            Biosql::Bioentry.where(:bioentry_id => hits.map{|h| h.stored(:id)}).includes(:biosequence_without_seq).each do |entry|
              # write the entry header
              out.write entry.genbank_header
              # process the features in batches (for manageable includes)
              Biosql::Feature::Seqfeature.where(:bioentry_id => entry.id).includes{[type_term,qualifiers.term,locations]}.find_in_batches(:batch_size => 500) do |feature_batch|
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
          end
        }
      }
      wants.json {
        search = base_search do |s|
          s.paginate(:page => params[:page], :per_page => params[:limit])
        end
        data=[]
        search.results.each do |entry|
         # b = Biosql::Bioentry.find(entry.id, :include => [:assembly,[:source_features => [:qualifiers => :term]]] )
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
    @bioentry = Biosql::Bioentry.find(params[:id])
    authorize! :read, @bioentry
    assembly = @bioentry.assembly
    # the feature_id will be used to lookup the given feature on load. It will NOT set the position.
    @feature_id = params[:feature_id]
    @gene_id = params[:gene_id]
    ## get layout id
    # selecting default layout resets preferred layout
    if(params[:default])
      current_user.preferred_track_layout=nil, assembly
      current_user.save!
      layout_id = nil
    # passing layout_id sets preferred layout
    elsif params[:layout_id]
      layout_id = params[:layout_id]
      current_user.preferred_track_layout=layout_id, assembly
      current_user.save!
    # lookup preferred layout if no explicit tracks set
    else
      layout_id = current_user.preferred_track_layout(assembly) unless params[:track]
    end
    ## Setup the Active Tracks
    # if we have a layout_id find the layout and set the active tracks
    if(layout_id)
      begin
        @layout = TrackLayout.find(layout_id)
        @active_track_string = @layout.active_tracks
      rescue
        @layout = nil
      end
    # otherwise check the parameters for track ids
    elsif(params[:tracks])
      # use tracks param. no reason to sanitize because track_ids are only loaded if they exist
      @active_tracks = Array(params[:tracks])
    # fallback on default tracks
    else
      @active_tracks =[assembly.six_frame_track.try(:id),assembly.models_tracks.first.try(:id)]
    end
    # Scope track access by ability
    # Active tracks will be ignored if not in this list
    @all_tracks = assembly.tracks.accessible_by(current_ability)
    # We add the non-experiment tracks. There are not 'accessible_by' normal users in can can
    # Instead, they are always accessible if the bioentry is accessible
    @all_tracks += [assembly.six_frame_track,assembly.models_tracks,assembly.generic_feature_tracks].flatten.compact
    # admin users will see non-experiment tracks twice if we don't uniq the list
    @all_tracks.uniq!
    # Setup the view
    @view ={
      :position => params[:pos]||params[:position]||@layout.try(:position)||1,
      :bases => params[:b]||params[:bases]||@layout.try(:bases)||50,
      :pixels => params[:p]||params[:pixels]||@layout.try(:pixels)||1
    }

    render :layout => 'sequence_viewer'
  end
  
  def edit
    @bioentry = Biosql::Bioentry.find(params[:id])
    authorize! :update, @bioentry
  end

  def update
    @bioentry = Biosql::Bioentry.find(params[:id])
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
    bioentry = Biosql::Bioentry.find(bioentry_id)
    # auth
    authorize! :read, bioentry
    bioentry_tv = bioentry.assembly
    bioentry_sp = bioentry_tv.species
    assemblies = bioentry_sp.species_assemblies.accessible_by(current_ability).includes(:taxon)
    # Collect Species
    Biosql::Taxon.with_species_assemblies.accessible_by(current_ability).each do |taxon|
      species_array.push({
        :id => taxon.species_assemblies.first.bioentries.first.try(:id),
        :name => taxon.name
      })
    end
    # Collect Strain/Variety/SubTaxon
    assemblies.map(&:taxon).uniq.each do |taxon_strain|
      taxons.push({
        :id => taxon_strain.assemblies.accessible_by(current_ability).first.bioentries.first.try(:id),
        :name => (taxon_strain == bioentry_sp) ? "Generic Strain" : taxon_strain.name
      })
    end
    # Collect Version
    assemblies.each do |assembly|
      versions.push({
        :id => assembly.bioentries.first.try(:id),
        :name => assembly.version
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
          :assembly_id => bioentry_tv.id
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
        #TODO: Remove or use syndication data
        render :json  => {
          :success => true,
          :data => {
            :institution => {
              :name => "GLBRC",
              :url => 'http://www.glbrc.org',
              :logo => "http://glbrc.org/sites/all/themes/gbif/images/GLBRC_horz_cmyk_small.jpg"
            },
            :engineer => {
              :name => "Nicholas A. Thrower",
              :email => "throwern@msu.edu"
            },
            :service => {
              :title => "Genome Sequence",
              :species => "",
              :access => "GLBRC",
              :version => "",
              :format => "1",
              :server => "1",
              :description => ""
            }
          }
        }
       when 'sequence'
         bioentry_id = param['bioentry']
         bioentry = Biosql::Bioentry.find(bioentry_id)
         authorize! :read, bioentry
         biosequence = bioentry.biosequence_without_seq
         render :partial => "biosequence/show", :locals => {:biosequence => biosequence, :start => param['left'], :stop => param['right']}
       when 'range'
         bioentry_id = param['bioentry']
         bioentry = Biosql::Bioentry.find(bioentry_id)
         bioseq = bioentry.biosequence_without_seq
         authorize! :read, bioentry
         left = param['left']
         right = param['right']
         length = right - left +1
         if(param['bases']==1 && param['pixels']>1)
           sequence = bioseq.get_seq( left, length )
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
           sequence = bioseq.get_seq( left, length )
           data = bioseq.get_six_frames(left, right)
           render :json => {
              :success => true,
                :data => {
                  :sequence  => {
                    :seq  =>[# [id,x,w,sequence]
                      [left+1, left+1, length, sequence]
                    ],
                    :gc_content => [# [id,x,w,sequence]
                        [left+1, left + 1, length, bioentry.get_gc_content(left,length,param['bases'])]
                     ]
                  },
                :sixframe => {# [id,x,w,sequence,frame#,offset]..]
                   :frame => data     
                }
              }
           }
         elsif(param['bases']>=10)
          data =  bioentry.get_gc_content(left,length,param['bases'])
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
    authorized_id_set = current_ability.authorized_bioentry_ids
    # Set to -1 if no items are found. This will force empty search results
    authorized_id_set=[-1] if authorized_id_set.empty?
    # Begin block
    @search = Biosql::Bioentry.search do |s|
      # Text Keywords
      if params[:keywords]
        s.keywords params[:keywords], :fields => [:accession_text,:description_text,:sequence_type_text,:sequence_name_text,:species_name_text,:assembly_name_text], :highlight => true
      end
      # Auth      
      s.any_of do |any_s|
        authorized_id_set.each do |id_range|
          any_s.with :id, id_range
        end
      end
      # Filters
      s.with :assembly_id, params[:assembly] unless params[:assembly].blank?
      # TODO: Hash out use case for biodatabase segmentation
      #s.with :biodatabase_id, params[:biodatabase] unless params[:biodatabase].blank?
      s.with :assembly_type, params[:taxon_type] unless params[:taxon_type].blank?
      # Sort
      s.order_by params[:c].to_sym, order_d
      # Paging + extras
      yield(s)
    end
  end
  
end
