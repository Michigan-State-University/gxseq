class GenericFeatureController < ApplicationController
   include ActionView::Helpers::TextHelper
   
   def jrws
      my_object = params[:jrws]
      send my_object.method
   end
 
   def gene_models
      
      unless params[:jrws].blank?
         jrws = JSON.parse(params[:jrws])
         param = jrws['param']
         case jrws['method']
            when 'select' 
              seqfeature_keys = Bio::Term.annotation_tags.collect {|x| x.name }
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
                        :description => "These models have been loaded from the GLBRC Genome Suite"
                     }
                  }
               }
            when 'describe'
              begin
                @seqfeature = Bio::Feature::Seqfeature.find(param['id'])
                authorize! :read, @seqfeature
                @ontologies = Bio::Term.annotation_ontologies
                render :partial => "seqfeatures/info.json"
              rescue
                render :json => {
                  :success => false,
                  :message => "Not Found"
                }
              end
            when 'range'
              #Needs refactoring - some data being sent is redundant/unused
                bioentry = Bio::Bioentry.find(param['bioentry'])
                authorize! :read, bioentry
                my_data = Bio::Feature::Seqfeature.get_track_data(param['left'],param['right'],param['bioentry']) 
            render :json => {
              :success => true,
              :data => my_data
            }
         end
      else
         if(params[:annoj_action] == 'lookup')
             show = ["product"]
             bioentry = Bio::Bioentry.find(params['bioentry'])
             authorize! :read, bioentry
             bioentry_ids = bioentry.assembly.bioentries.map(&:id)
             features = Bio::Feature::Seqfeature.joins{qualifiers.term}
              .includes( [:locations, [:qualifiers => [:term]]])
              .order("term.name").where{qualifiers.term.name != 'translation'}
              .where("UPPER(value) like '%#{params[:query].upcase}%' AND bioentry_id in (#{bioentry_ids.join(',')})")

             data = []
             features[params[:start].to_i,params[:limit].to_i].each do |feature|
                info = "<br/>"
                match = ""
                max_pre_char = 35
                max_line_char = 35
                max_total_char = 100
                feature.qualifiers.each do |q|
                  if(pos = q.value.upcase=~(/#{params[:query].upcase}/))
                    match = "<b>#{q.term.name}:</b>"
                    text=q.value
                    if(pos > max_pre_char)
                      text = "..."+text[pos-max_pre_char, (text.length-(pos-max_pre_char))]
                    end    
                    text.gsub!(/(.{1,#{max_line_char}})( +|$\n?)|(.{1,#{max_line_char}})/,"\\1\\3\n")
                    text = truncate(text, :length => 70)
                    match += highlight(text, params[:query], :highlighter => '<b class="darkred">\1</b>')
                  end
                end
                
                type = feature.display_name
                if(feature.locus_tag)
                   type += ":"+feature.locus_tag.value
                elsif (feature.gene)
                   type += ":"+feature.gene.value
                end 
                
                data.push( {
                   :id => feature.id.to_s,
                   :type => type,
                   :bioentry => feature.bioentry.display_name,
                   :bioentry_id => feature.bioentry_id,
                   :start => feature.locations.first.start_pos,
                   :end => feature.locations.last.end_pos,
                   :match => match,
                   :reload_url => bioentries_path                             
                })
             end
             render :json  => {
                :success => true,
                :count => features.size,
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