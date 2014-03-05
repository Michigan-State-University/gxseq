class Track::ReadsController < Track::BaseController
  before_filter :authorize_sample
  before_filter :authorize_bioentry, :except => :syndicate
  def syndicate
    render :partial => "track/sample_info.json", :locals => {:track => @sample.reads_track}
  end

  def show
    pos = params[:pos].to_i
    c_item = @sample.concordance_items.with_bioentry(@bioentry.id)[0]
    @read = @sample.find_read(params[:id],c_item.reference_name,pos)
    render :partial => "track/read_details"
  end

  def range
    c_item = @sample.concordance_items.with_bioentry(@bioentry)[0]
    unless(c_item && @bioentry && @sample && @sample.respond_to?(:get_reads))
      render :json => {:success => false}
      return
    end
    density=(params[:density]||1000).to_i
    right=params[:right].to_i
    left=params[:left].to_i
    offset = (right-left)/density.to_f
    if(@sample.single)
      data = @sample.summary_data(left,right,density,c_item.reference_name)
      data.fill{|i| [left+(i*offset).to_i,data[i].to_i]}
      render :text =>"{\"success\":true,\"data\":{\"above\":#{data.inspect}}}"
    else
      data = @sample.summary_data(left,right,density,c_item.reference_name,{:strand => '+'})
      data.fill{|i| [left+(i*offset).to_i,data[i].to_i]}
      data_below = @sample.summary_data(left,right,density,c_item.reference_name,{:strand => '-'})
      data_below.fill{|i| [left+(i*offset).to_i,data_below[i].to_i]}
      render :text =>"{\"success\":true,\"data\":{\"above\":#{data.inspect},\"below\":#{data_below.inspect}}}"
    end
  end

  def reads
    c_item = @sample.concordance_items.with_bioentry(@bioentry)[0]
    unless(c_item && @bioentry && @sample && @sample.respond_to?(:get_reads))
      render :json => {:success => false}
      return
    end
    right=params[:right].to_i
    left=params[:left].to_i
    reads_text = @sample.get_reads_text(left,right,c_item.reference_name,{:include_seq => true, :read_limit => params[:read_limit]})
    render :text => "{\"success\":true,\"data\":{#{"\"notice\": \"#{reads_text[2]} of #{reads_text[1]} reads\","}\"reads\":["+reads_text[0]+"]}}"
  end
end