class ProteinSequenceController < ApplicationController
   skip_before_filter :verify_authenticity_token
   include ActionView::Helpers::TextHelper
   
   def jrws
      my_object = params[:jrws]
      send my_object.method
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
        when 'range'
           bioentry = param['bioentry']
           if(param['bases']>1)
              bioseq = Bio::Bioentry.find(bioentry).biosequence
              left = param['left']
              right = param['right']
              length = right - left +1
              sequence = bioseq.seq[ left, length ]
              protein_data = bioseq.get_protein_sequence(bioseq.bioentry_id+left, left, right)
              render :json => {
                 :success => true,
                 :data => protein_data
              }             
           elsif(param['bases']==1)
              if(param['pixels']>=1)
                 bioseq = Bio::Bioentry.find(bioentry).biosequence
                 left = param['left']
                 right = param['right']
                 length = right - left +1
                 sequence = bioseq.seq[ left, length ]

                 protein_data = bioseq.get_protein_sequence(bioseq.bioentry_id+left, left, right)
                 render :json => {
                    :success => true,
                    :data => protein_data
                 }
              elsif(param[:pixels]==0)
                render :json  => "{'success':true,'data':{}}"
              else
                render :json  => {
                  :success  => true
                }
              end
           end
         end
      else
        render :json => {
           :succes => false
        }
      end   
   end
end