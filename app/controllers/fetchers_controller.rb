class FetchersController < ApplicationController
   include ActionView::Helpers::TextHelper
  def metadata
    #syndication response
    jrws = JSON.parse(params[:jrws])
    param = jrws['param']
    bioentry_id = param['bioentry']
    bioentries = []
    species_array = []
    versions = []
    taxons = []
    bioentry = Bioentry.find(bioentry_id)
    species = bioentry.taxon_version.species
    Taxon.in_use_species.each do |taxon|
      species_array.push({
        :id => taxon.in_use_children.first.taxon_versions.first.bioentries.first.id,
        :name => taxon.name
      })
    end
    species.in_use_children.each do |taxon|
      if(taxon == species)
        taxons.push({
          :id => (taxon.taxon_versions.first.bioentries.first.id rescue bioentry_id),
          :name => "Generic Strain"
        })
      else
        taxons.push({
          :id => taxon.taxon_versions.first.bioentries.first.id,
          :name => taxon.name
        })
      end
    end
    
    species.species_versions.each do |v|
      versions.push({
        :id => (v.bioentries.first.id rescue bioentry_id),
        :name => v.version
      })
    end
    
    bioentry.taxon_version.bioentries.includes(:source_features => :qualifiers).each do |b|
      bioentries.push({
        :id => b.id,
        :accession => b.accession,
        :name => b.generic_label, # we usually only have one source what do we show if there are more?
      })
    end
    #sort the sequence list, this converts everything to integer, Long strings i.e mitochondria/plasmid will be sorted arbitrarily
    bioentries.sort!{|a,b| (a[:name].is_roman_numeral? ? a[:name].to_i_roman : a[:name].to_i) <=> (b[:name].is_roman_numeral? ? b[:name].to_i_roman : b[:name].to_i) }
    render :json  => {
         :success => true, 
         :data => {
            :institution => {
               :name => 'Great Lakes Bioenergy Research Center',
               :url => 'http://www.glbrc.org',
               :logo => "http://glbrc.org/sites/all/themes/gbif/images/GLBRC_horz_cmyk_small.jpg"
            },
            :engineer => {
               :name => 'Nick Thrower', 
               :email => 'throwern@msu.edu'
            },
            :service => {
               :title => species.name,
               :copyright => 'Copyright 2008 GLBRC', 
               :license => 'http://creativecommons.org',
               :version => '2008-Dec-09',
               :entry_url => bioentries_path,
               :description => ''
            },
            :species => {
              :data => species_array, 
              :selected => species.name
            },
            :taxons => {
              :data => taxons, 
              :selected => (bioentry.taxon_version.taxon == bioentry.taxon_version.species ? "Generic Strain" : bioentry.taxon_version.name)
            },
            :versions => {
              :data => versions,
              :selected => bioentry.taxon_version.version
            },
            :entries => {
              :data => bioentries, 
              :selected => bioentry.generic_label # AGAIN, we usually only have one source what do we show if there are more?
            },
            :entry => {
               :accession => bioentry.accession,
               :accession_link => ACCESSION_LINK,
               :size => (bioentry.biosequence_without_seq.length rescue 1000),
            }
         }
      }
  end
   
   def base_counts
      jrws = JSON.parse(params[:jrws])
      param = jrws['param']
      case jrws['method']
      when 'syndicate'
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
                  :title => "GeneModels",
                  :species => "",
                  :access => "",
                  :version => "",
                  :format => "",
                  :server => "",
                  :description => "Base Counts Track"
               }
            }
         }         
    when 'range'
      bioentry = param['bioentry']
      exp = Experiment.find(param['experiment'])
      be = exp.bioentries_experiments.with_bioentry(bioentry)[0]
      data = exp.summary_data(param['left'],param['right'],((param['right']-param['left'])/param['bases']),be.sequence_name)
      #{(stop-start)/bases
      data.fill{|i| [param['left']+(i*param['bases']),data[i]]}

      #We Render the text directly for speed efficiency
      render :text =>"{\"success\":true,\"data\":#{data.inspect}}"
    when 'abs_max'
      exp = Experiment.find(param['experiment'])
      render :text => exp.max(exp.get_chrom(param['bioentry'])).to_s
    when 'peak_genes'
      @experiment = Experiment.find(param['experiment'])
      @bioentry_id = param['bioentry']
      render :partial => 'peaks/gene_list.json' #exp.peaks.with_bioentry(param['bioentry']).order(:pos).to_json(:only => [:id,:pos, :val], :methods => :genes_link)
    when 'peak_locations'
      exp = Experiment.find(param['experiment'])
      render :text => exp.peaks.with_bioentry(param['bioentry']).order(:pos).map{|p|{:pos => p.pos, :id => p.id}}.to_json
    end
   end
         
   def gene_models
      
      unless params[:jrws].blank?
         jrws = JSON.parse(params[:jrws])
         param = jrws['param']
         case jrws['method']
           
            when 'select'    
                bioentry = param['bioentry']
                seqfeature_name = Array.new
                seqfeature_keys = Ontology.find_by_name('Annotation Tags').terms.collect {|x| x.name }
              render :json  => {
               :success  => true,
               :data  => seqfeature_keys            
              }
            when 'syndicate'
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
                        :title => "GeneModels",
                        :species => "",
                        :access => "",
                        :version => "",
                        :format => "",
                        :server => "",
                        :description => "These models are representative of a full genome and have been loaded from a GLBRC biosql database containing the data within a Genbank file"
                     }
                  }
               }
            when 'describe'
              begin
                begin
                  @gene_model = GeneModel.find(param['id'])
                rescue
                  @gene_model = Seqfeature.find(param['id']).gene_model
                end
                @cds = @gene_model.cds
                @gene = @gene_model.gene
                @mrna = @gene_model.mrna
                render :partial => "genes/info.json"
              rescue
                render :json => {
                  :success => false,
                  :message => "Not Found"
                }
                logger.info "\n\n#{$!}\n\n"
              end
            when 'range'
              #Needs refactoring - some data being sent is redundant/unused
                bioentry = Bioentry.find(param['bioentry'])
                my_data = GeneModel.get_track_data(param['left'],param['right'],param['bioentry'],500) 
            render :json => {
              :success => true,
              :data => my_data
            }
         end
      else
         if(params[:annoj_action] == 'lookup')
             bioentry = Bioentry.find(params['bioentry'])
             bioentry_ids = bioentry.taxon_version.bioentries.map(&:id)
             
             data = []
             do_not_search_terms = ['translation','codon_start']
             
             if(params[:query] && !params[:query].blank?)
               query = params[:query].upcase
               qualifiers = SeqfeatureQualifierValue.limit(1000).includes([:term,:seqfeature]).where{seqfeature.bioentry_id.in bioentry_ids}.where{seqfeature.display_name.in GeneModel.seqfeature_types }.where{term.name.not_in(do_not_search_terms)}.where{upper(value)=~"%#{query}%"}
               ids = qualifiers.collect{|q|q.seqfeature.id}
               gene_models = GeneModel.where{(cds_id.in ids) | (mrna_id.in ids) | (gene_id.in ids)}.includes{[gene.qualifiers, cds.qualifiers, mrna.qualifiers]}.paginate({:page => params[:page],:per_page => params[:limit]})
             else
               gene_models = GeneModel.where{bioentry_id.in bioentry_ids}.order(:bioentry_id, :locus_tag).includes{[gene.qualifiers, cds.qualifiers, mrna.qualifiers]}.paginate({:page => params[:page],:per_page => params[:limit]})
             end
             # Collect the data and matching result             
             gene_models.each do |gene_model|                
                info = "<br/>"
                match = ""
                max_pre_char = 35
                max_line_char = 35
                max_total_char = 100
                if(query)
                  ["gene","cds","mrna"].each do |feature|
                      if fea = gene_model.send(feature)
                          fea.qualifiers.each do |q|
                              # don't match non-search terms
                              next if(do_not_search_terms.include?(q.term.name))
                              # avoid repeats
                              next if(q.term.name=='locus_tag'||q.term.name=='gene') unless feature =='gene'
                              # highlight the first matching qualifier for this feature
                              if(pos = q.value(false).upcase=~(/#{params[:query].upcase}/))
                                match = "<b>#{q.term.name}:</b>"
                                text=q.value(false)
                                if(pos > max_pre_char)
                                 text = "..."+text[pos-max_pre_char, (text.length-(pos-max_pre_char))]
                                end    
                                text.gsub!(/(.{1,#{max_line_char}})( +|$\n?)|(.{1,#{max_line_char}})/,"\\1\\3\n")
                                text = truncate(text, :length => 70)
                                match += highlight(text, params[:query], :highlighter => '<b class="darkred">\1</b>')
                                break
                              end
                           end
                       end
                   end
                 end
                data.push( {
                   :id => gene_model.id.to_s,
                   :type => gene_model.display_name,
                   :bioentry => gene_model.bioentry.display_name,
                   :bioentry_id => gene_model.bioentry_id,
                   :start => gene_model.start_pos,
                   :end => gene_model.end_pos,
                   :match => match,
                   :reload_url => bioentries_path                         
                })
             end
             # render the match
             render :json  => {
                :success => true,
                :count => gene_models.total_entries,
                :rows => data
             }
          
         else 
            render :json => {
               :succes => false
            }
         end
      end
      
   end
   
   def genome
     # total_width = 1760
     unless params[:jrws].blank?
        jrws = JSON.parse(params[:jrws])
        param = jrws['param']
        case jrws['method']
        when 'syndicate'
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
          biosequence = Biosequence.find_by_bioentry_id(bioentry_id)
          render :partial => "biosequence/show", :locals => {:biosequence => biosequence, :start => param['left'], :stop => param['right']}
        when 'range'
          bioentry = param['bioentry']
          bioseq = Biosequence.find_by_bioentry_id(bioentry)
          left = param['left']
          right = param['right']
          length = right - left +1
          
          if(param['bases']==1 && param['pixels']>1)
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
            d =  bioseq.get_gc_content(left,length,param['bases'])
           render :json => {
              :success => true,
                :data => {
                  :sequence  => {
                    :gc_content => [# [id,x,w,sequence]
                        [left+1, left + 1, length, d] 
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
end