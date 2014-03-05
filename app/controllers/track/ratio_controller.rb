class Track::RatioController < Track::BaseController
  before_filter :authorize_sample
  before_filter :authorize_bioentry, :except => :syndicate
  
  def syndicate
    render :partial => "synthetics/sample_info.json", :locals => {:track => @sample.ratio_track}
  end
  
  def range
    c_item = @sample.concordance_items.with_bioentry(@bioentry.id)[0]
    density=(params[:density]||1000).to_i
    left=params[:left].to_i
    right=params[:right].to_i
    data = @sample.summary_data(left,right,density,c_item.reference_name)
    offset = (right-left)/density.to_f
    # fix infinity to max
    absMax = data.map(&:abs).reject{|x|x==Float::INFINITY}.uniq
    absMax = absMax.max
    data.fill{|i| data[i]==Float::INFINITY ? 1 : data[i]}
    # convert to LOG(10)
    data.fill{|i| data[i]==0 ? 0 : Math.log(data[i])}
    # fill with x range
    data.fill{|i| [left+(i*offset).to_i,data[i].round(2)]}
    render :text =>"{\"success\":true,\"data\":#{data.inspect}}"
  end
end