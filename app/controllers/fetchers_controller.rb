class FetchersController < ApplicationController
  # TODO: Refactor fetchers controller placing code in appropriate models/decorators etc...
   include ActionView::Helpers::TextHelper
   
   # Histogram Track data
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
      bioentry_id = param['bioentry']
      bioentry = Biosql::Bioentry.find(bioentry_id)
      sample = Sample.find(param['sample'])
      authorize! :track_data, sample
      c_item = sample.concordance_items.with_bioentry(bioentry_id)[0]
      density=param['density']||1000
      data = sample.summary_data(param['left'],param['right'],density,c_item.reference_name)
      offset = (param['right']-param['left'])/density.to_f
      #{(stop-start)/bases
      data.fill{|i| [param['left']+(i*offset).to_i,data[i].round(2)]}
      #We Render the text directly for speed efficiency
      render :text =>"{\"success\":true,\"data\":{\"above\":#{data.inspect}}}"
    when 'peak_genes'
      @sample = Sample.find(param['sample'])
      authorize! :track_data, @sample
      @bioentry_id = param['bioentry']
      bioentry = Biosql::Bioentry.find(@bioentry_id)
      render :partial => 'peaks/gene_list.json' #sample.peaks.with_bioentry(param['bioentry']).order(:pos).to_json(:only => [:id,:pos, :val], :methods => :genes_link)
    when 'peak_locations'
      sample = Sample.find(param['sample'])
      authorize! :track_data, sample
      bioentry_id = param['bioentry']
      bioentry = Biosql::Bioentry.find(bioentry_id)
      render :text => sample.peaks.with_bioentry(param['bioentry']).order(:pos).map{|p|{:pos => p.pos, :id => p.id}}.to_json
    end
   end
   
   # Models Track data
   def gene_models
      unless params[:jrws].blank?
         jrws = JSON.parse(params[:jrws])
         param = jrws['param']
         case jrws['method']
            when 'select'    
              seqfeature_keys = Biosql::Term.annotation_tags.collect {|x| x.name }
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
                  @gene_model = GeneModel.find_by_id(param['id']) || Biosql::Feature::Seqfeature.find(param['id']).gene_model
                end
                authorize! :read, @gene_model
                @cds = @gene_model.cds
                @gene = @gene_model.gene
                @mrna = @gene_model.mrna
                @ontologies = Biosql::Term.annotation_ontologies
                render :partial => "biosql/feature/genes/info.json"
              rescue => e
                render :json => {
                  :success => false,
                  :message => "Not Found"
                }
                logger.info "\n\n#{$!}\n\n#{e.backtrace.join("\n")}"
              end
            when 'range'
              #Needs refactoring - some data being sent is redundant/unused
              bioentry = Biosql::Bioentry.find(param['bioentry'])
              authorize! :read, bioentry
              my_data = GeneModel.get_track_data(param['left'],param['right'],param['bioentry'],500) 
            render :json => {
              :success => true,
              :data => my_data
            }
         end
      else
         if(params[:annoj_action] == 'lookup')
             bioentry = Biosql::Bioentry.find(params['bioentry'])
             bioentry_ids = bioentry.assembly.bioentries.map(&:id)
             authorize! :read, bioentry
             data = []
             
             if(params[:query] && !params[:query].blank?)
               query = params[:query].upcase
               qualifiers = Biosql::SeqfeatureQualifierValue.limit(1000).includes([:term,:seqfeature]).where{seqfeature.bioentry_id.in bioentry_ids}.where{seqfeature.display_name.in GeneModel.seqfeature_types }.where{term.name.not_in(Biosql::Feature::Seqfeature.excluded_search_terms)}.where{upper(value)=~"%#{query}%"}
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
                              next if(Biosql::Feature::Seqfeature.excluded_search_terms.include?(q.term.name))
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
   

end