class Track::RatioController < Track::BaseController
  before_filter :authorize_sample
  before_filter :authorize_bioentry, :except => :syndicate
  
  def syndicate
    render :partial => "synthetics/sample_info.json", :locals => {:track => @sample.ratio_track}
  end
  
  def range
    density=(params[:density]||1000).to_i
    left=params[:left].to_i
    right=params[:right].to_i
    offset = (right-left)/density.to_f
    # get stats
    mad = @sample.median_absolute_deviation(@bioentry)
    median = @sample.median(@bioentry)
    # get data
    data = @sample.summary_data(left,right,density,@bioentry)
    # fill with x range
    data.fill{|i| [left+(i*offset).to_i,data[i]]}
    render :text =>"{\"success\":true,\"data\":{\"ratio\":#{data.inspect},\"mad\":#{mad},\"median\":#{median}}}"
  end
end