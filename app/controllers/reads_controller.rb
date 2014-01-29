class ReadsController < ApplicationController
  @@range_summary={}
  @@range_reads={}
  def track_data
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
                  :title => "Reads",
                  :species => "",
                  :access => "",
                  :version => "",
                  :format => "",
                  :server => "",
                  :description => "Sequence Reads Track"
               }
            }
         }
      when 'abs_max'
        sample= Sample.find(param['sample'])
        render :text => sample.max(sample.sequence_name(param['bioentry'])).to_s
      when 'range'
        bioentry = Biosql::Bioentry.find(param['bioentry'])
        sample = Sample.find(param['sample'])
        authorize! :track_data, sample
        c_item = sample.concordance_items.with_bioentry(bioentry)[0]
        unless(c_item && bioentry && sample && sample.respond_to?(:get_reads))
          render :json => {:success => false}
          return
        end
        density=param['density']||1000
        data = sample.summary_data(param['left'],param['right'],density,c_item.reference_name)
        offset = (param['right']-param['left'])/density.to_f
        #{(stop-start)/bases
        data.fill{|i| [param['left']+(i*offset).to_i,data[i].to_i]}
        render :text =>"{\"success\":true,\"data\":#{data.inspect}}"
      when 'reads'
        bioentry = Biosql::Bioentry.find(param['bioentry'])
        sample = Sample.find(param['sample'])
        authorize! :track_data, sample
        c_item = sample.concordance_items.with_bioentry(bioentry)[0]
        unless(c_item && bioentry && sample && sample.respond_to?(:get_reads))
          render :json => {:success => false}
          return
        end
         reads_text = sample.get_reads_text(param['left'],param['right'],c_item.reference_name,{:include_seq => true, :read_limit => param['read_limit']})
         render :text => "{\"success\":true,\"data\":{#{"\"notice\": \"#{reads_text[2]} of #{reads_text[1]} reads\","}\"reads\":["+reads_text[0]+"]}}"
      when 'describe'
        bioentry_id = Biosql::Bioentry.find(param['bioentry'])
        sample = Sample.find(param['sample'])
        authorize! :track_data, sample
        pos = param['pos']
        c_item = sample.concordance_items.with_bioentry(bioentry_id)[0]
        @read = sample.find_read(param['id'],c_item.reference_name,pos)
        render :partial => "reads/show"
      end
      
    end

  end
end