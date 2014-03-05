class Track::DensityController < Track::BaseController
  before_filter :authorize_sample
  before_filter :authorize_bioentry, :except => :syndicate
  
  def syndicate
    render :partial => "track/sample_info.json", :locals => {:track => @sample.histogram_track}
  end
  
  def range
    c_item = @sample.concordance_items.with_bioentry(@bioentry.id)[0]
    density=(params[:density]||1000).to_i
    left=params[:left].to_i
    right=params[:right].to_i
    data = @sample.summary_data(left,right,density,c_item.reference_name)
    offset = (right-left)/density.to_f
    #{(stop-start)/bases
    data.fill{|i| [left+(i*offset).to_i,data[i].round(2)]}
    render :text =>"{\"success\":true,\"data\":{\"above\":#{data.inspect}}}"
  end
  
  def peak_genes
    bioentry = Biosql::Bioentry.find(@bioentry.id)
    render :partial => 'peaks/gene_list.json'
  end
  
  def peak_locations
    bioentry = Biosql::Bioentry.find(@bioentry.id)
    render :text => @sample.peaks.with_bioentry(@bioentry.id).order(:pos).map{|p|{:pos => p.pos, :id => p.id}}.to_json
  end
end