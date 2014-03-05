class Track::VariantsController < Track::BaseController
  before_filter :authorize_sample
  before_filter :authorize_bioentry, :except => :syndicate
  def syndicate
    render :partial => "track/sample_info.json", :locals => {:track => @sample.variant_tracks.first}
  end
  
  def show
    begin
      c_item = @sample.concordance_items.find_by_bioentry_id(@bioentry.id)
      @position = params[:id].to_i
      @variants = @sample.find_variants(c_item.reference_name,@position)
      render :partial => "variants/item"
    rescue
      render :json => {
        :success => false,
        :message => "Not Found"
      }
      logger.info "\n\n#{$!}\n\n"
    end
  end
  
  def range
    genotype_sample = params[:genotype_sample]
    left = params[:left].to_i
    right = params[:right].to_i
    limit = 5000
    only_variants_flag = (right-left>1000)
    c_item = @sample.concordance_items.find_by_bioentry_id(@bioentry.id)
    data = {}
    @sample.get_data(c_item.reference_name, left, right, {:limit => limit, :sample => genotype_sample, :split_hets => true, :only_variants => only_variants_flag}).each do |v|  
      data[v[:type]] ||=[]
      data[v[:type]] << [v[:allele],v[:id],v[:pos],v[:ref].length,v[:ref],v[:alt],v[:qual]]
    end
    render :json => {
      :success => true,
      :data => data
    }
  end
  
  def match_tracks
    begin
      @left = params[:left].to_i
      @right = params[:right].to_i
      render :partial => "variants/info.json"
    rescue => e
      render :json => {
        :success => true,
        :data => {
          :text => "Error"
        }
      }
      logger.info "\n\n#{$!}\n\n#{e.backtrace.join("\n")}"
    end
  end
  
end