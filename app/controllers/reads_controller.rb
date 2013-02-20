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
          data = experiment.summary_data(param['left'],param['right'],((param['right']-param['left'])/param['bases']),be.sequence_name)
          data = data.fill{|i| [param['left']+(i*param['bases']),data[i].to_i]}
          render :text =>"{\"success\":true,\"data\":#{data.inspect}}"
      when 'reads'
        bioentry = Bioentry.find(param['bioentry'])
        experiment = Experiment.find(param['experiment'])
        be = experiment.bioentries_experiments.with_bioentry(bioentry)[0]
        unless(be && bioentry && experiment && experiment.respond_to?(:get_reads))
          render :json => {:success => false}
          return
        end
         reads_text = experiment.get_reads_text(param['left'],param['right'],be.sequence_name,{:include_seq => true, :read_limit => param['read_limit']})
         render :text => "{\"success\":true,\"data\":{#{"\"notice\": \"#{reads_text[2]} of #{reads_text[1]} reads\","}\"reads\":["+reads_text[0]+"]}}"
      when 'describe'
        bioentry_id = Bioentry.find(param['bioentry'])
        experiment = Experiment.find(param['experiment'])
        pos = param['pos']
        be = experiment.bioentries_experiments.with_bioentry(bioentry_id)[0]
        @read = experiment.find_read(param['id'],be.sequence_name,pos)
        # if(@read && @read[:pos] && @read[:calend])
        #   @read[:ref_seq]=Bioentry.find(bioentry_id).biosequence.seq[@read[:pos]-1,(@read[:calend]-@read[:pos])+1]
        # end
        render :partial => "reads/show"
      end
      
    end

  end
end