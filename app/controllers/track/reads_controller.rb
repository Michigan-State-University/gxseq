class Track::ReadsController < Track::BaseController
  before_filter :authorize_sample
  before_filter :authorize_bioentry, :except => :syndicate
  def syndicate
    render :partial => "track/sample_info.json", :locals => {:track => @sample.reads_track}
  end

  def show
    pos = params[:pos].to_i
    @read = @sample.find_read(params[:id],@bioentry,pos)
    render :partial => "track/read_details"
  end

  def range
    unless(@bioentry && @sample && @sample.respond_to?(:get_reads))
      render :json => {:success => false}
      return
    end
    density=(params[:density]||1000).to_i
    right=params[:right].to_i
    left=params[:left].to_i
    offset = (right-left)/density.to_f
    if(@sample.single)
      data = @sample.summary_data(left,right,density,@bioentry)
      data.fill{|i| [left+(i*offset).to_i,data[i].to_i]}
      render :text =>"{\"success\":true,\"data\":{\"above\":#{data.inspect}}}"
    else
      data = @sample.summary_data(left,right,density,@bioentry,{:strand => '+'})
      data.fill{|i| [left+(i*offset).to_i,data[i].to_i]}
      data_below = @sample.summary_data(left,right,density,@bioentry,{:strand => '-'})
      data_below.fill{|i| [left+(i*offset).to_i,data_below[i].to_i]}
      render :text =>"{\"success\":true,\"data\":{\"above\":#{data.inspect},\"below\":#{data_below.inspect}}}"
    end
  end

  def reads
    unless(@bioentry && @sample && @sample.respond_to?(:get_reads))
      render :json => {:success => false}
      return
    end
    right=params[:right].to_i
    left=params[:left].to_i
    reads_text = @sample.get_reads_text(left,right,@bioentry,{:include_seq => true, :read_limit => params[:read_limit]})
    render :text => "{\"success\":true,\"data\":{#{"\"notice\": \"#{reads_text[2]} of #{reads_text[1]} reads\","}\"reads\":["+reads_text[0]+"]}}"
  end
  
  def peak_genes
    render :partial => 'peaks/gene_list.json'
  end
  
  def peak_locations
    render :text => @sample.peaks.with_bioentry(@bioentry.id).order(:pos).map{|p|{:pos => p.pos, :id => p.id}}.to_json
  end
end