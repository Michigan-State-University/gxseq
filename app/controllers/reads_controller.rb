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
        exp = Experiment.find(param['experiment'])
        render :text => exp.max(exp.get_chrom(param['bioentry'])).to_s
      when 'range'
        bioentry = Bioentry.find(param['bioentry'])
        experiment = Experiment.find(param['experiment'])
        be = experiment.bioentries_experiments.with_bioentry(bioentry)[0]
        unless(be && bioentry && experiment && experiment.respond_to?(:get_reads))
          render :json => {:success => false}
          return
        end
        #if(param['bases']>1)
          #data = @@range_summary["#{param['left']}#{param['right']}#{param['bases']}#{be.sequence_name}"]||=experiment.summary_data(param['left'],param['right'],((param['right']-param['left'])/param['bases']),be.sequence_name).fill{|i| [param['left']+(i*param['bases']),data[i]]}
          data = experiment.summary_data(param['left'],param['right'],((param['right']-param['left'])/param['bases']),be.sequence_name)
          data = data.fill{|i| [param['left']+(i*param['bases']),data[i]]}
          render :text =>"{\"success\":true,\"data\":#{data.inspect}}"
        # elsif(param['bases']==1)
        #    #reads = @@range_reads["#{param['left']}#{param['right']}#{be.sequence_name}"]||=experiment.get_reads(param['left'],param['right'],be.sequence_name)          
        #    if(param['pixels']==1)
        #      reads_text = experiment.get_reads_text(param['left'],param['right'],be.sequence_name,{:include_seq => false, :read_limit => param['read_limit']})
        #      render :text => "{\"success\":true,\"data\":{#{"\"notice\": \"#{reads_text[2]} of #{reads_text[1]} reads\","}\"line_above\":["+reads_text[0]+"]}}"
        #    elsif(param['pixels']==100)             
        #      reads_text = experiment.get_reads_text(param['left'],param['right'],be.sequence_name,{:include_seq => true, :read_limit => param['read_limit']})
        #      render :text => "{\"success\":true,\"data\":{#{"\"notice\": \"#{reads_text[2]} of #{reads_text[1]} reads\","}\"line_above\":["+reads_text[0]+"]}}"
        #    end
        # else
        #    render :text =>"{\"success\":false}"
        # end
      when 'reads'
        
      end
      
    end

  end
end