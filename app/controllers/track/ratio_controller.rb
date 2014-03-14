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
    offset = (right-left)/density.to_f
    # get stats
    mad = @sample.median_absolute_deviation(c_item)
    median = @sample.median(c_item)
    # get data
    data = @sample.summary_data(left,right,density,c_item.reference_name)
    # fill with x range
    data.fill{|i| [left+(i*offset).to_i,data[i]]}
    render :text =>"{\"success\":true,\"data\":{\"ratio\":#{data.inspect},\"mad\":#{mad},\"median\":#{median}}}"
  end
end