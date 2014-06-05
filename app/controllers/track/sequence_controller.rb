class Track::SequenceController < Track::BaseController
  before_filter :authorize_bioentry, :except => :syndicate
  def syndicate
    render :json  => {
      :success => true,
      :data => {
        :institution => {
          :name => "GLBRC",
          :url => 'http://www.glbrc.org',
          :logo => ""
        },
        :engineer => {
          :name => "",
          :email => ""
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
  end
  
  # SV App Data - syndication response
  # Expects: bioentry_id
  # Returns: JSON hash of service provider and sequence selection data
  def metadata
    # setup
    bioentries = []
    species_array = []
    versions = []
    taxons = []
    use_bioentry_search = false
    # auth
    bioentry_tv = @bioentry.assembly
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
          :logo => ""
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
          :selected => @bioentry.sequence_name,
          :use_search => use_bioentry_search,
          :search_url => bioentries_path(:format => :json),
          :assembly_id => bioentry_tv.id
        },
        :entry => {
          :accession => @bioentry.accession,
          :accession_link => bioentry_path(@bioentry,:fmt => 'genbank'),
          :size => (@bioentry.length),
        }
      }
    }
  end
  
  def range
    bioseq = @bioentry.biosequence_without_seq
    left = params[:left].to_i
    right = params[:right].to_i
    length = right - left +1
    bases = params[:bases].to_i
    if(bases==1 && params[:pixels].to_i>1)
      sequence = bioseq.get_seq( left, length )
      data = bioseq.get_six_frames(left, right)
      render :json => {
        :success => true,
        :data => {
          :sequence  => {
            :seq  =>[# [id,x,w,sequence]
              [left+1, left+1, length, sequence]
            ]},
            :sixframe => {# [id,x,w,sequence,frame#,offset]..]
              :frame => data     
            }
          }
        }            
      elsif(bases < 10 )
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
                [left+1, left + 1, length, @bioentry.get_gc_content(left,length,bases)]
            ]},
            :sixframe => {# [id,x,w,sequence,frame#,offset]..]
              :frame => data     
            }
          }
        }
      elsif(bases>=10)
        data =  @bioentry.get_gc_content(left,length,bases)
        render :json => {
          :success => true,
          :data => {
            :sequence  => {
              :gc_content => [# [id,x,w,sequence]
              [left+1, left + 1, length, data] 
            ]},
          }
        }
      else
        render :json  => {
          :success  => false
        }
      end
    end
  
  def sequence
    biosequence = @bioentry.biosequence_without_seq
    left = [params[:left].to_i,1].max
    render :partial => "biosequence/show", :locals => {:biosequence => biosequence, :start => left, :stop => params[:right].to_i}
  end
  
end