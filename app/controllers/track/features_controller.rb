class Track::FeaturesController < Track::BaseController
  before_filter :authorize_bioentry, :except => [:syndicate,:show]
  def syndicate
    render :json  => {
      :success => true,
      :data => {
        :institution => {
          :name => "GLBRC",
          :url => 'http://www.glbrc.org',
          :logo => ""
        },
        :engineer => {
          :name => "",
          :email => ""
        },
        :service => {
          :title => "Features",
          :species => "",
          :access => "GLBRC",
          :version => "",
          :format => "1",
          :server => "1",
          :description => ""
        }
      }
    }
  end
  
  def show
    begin
      @seqfeature = Biosql::Feature::Seqfeature.find(params[:id])
      authorize! :read, @seqfeature
      @ontologies = Biosql::Term.annotation_ontologies
      render :partial => '/biosql/feature/seqfeatures/info.json'
    rescue => e
      server_error(e,"Error Describing Generic Feature")
      render :json => {
        :success => false,
        :message => "Not Found"
      }
    end
  end
  
  def range
    my_data = Biosql::Feature::Seqfeature.get_track_data(params[:left].to_i,params[:right].to_i,@bioentry.id) 
    render :json => {
      :success => true,
      :data => my_data
    }
  end
  
  def search
    show = ["product"]
    #bioentry_ids = @bioentry.assembly.bioentries.map(&:id)
    features = Biosql::Feature::Seqfeature.joins{qualifiers.term}
    .includes( [:locations, [:qualifiers => [:term]]])
    .order("term.name").where{qualifiers.term.name != 'translation'}
    .where("UPPER(value) like '%#{params[:query].upcase}%' AND bioentry_id = #{@bioentry.id}")
    #.where("UPPER(value) like '%#{params[:query].upcase}%' AND bioentry_id in (#{bioentry_ids.join(',')})")

    data = []
    features[params[:start].to_i,params[:limit].to_i].each do |feature|
      info = "<br/>"
      match = ""
      max_pre_char = 35
      max_line_char = 35
      max_total_char = 100
      feature.qualifiers.each do |q|
        if(pos = q.value.upcase=~(/#{params[:query].upcase}/))
          match = "<b>#{q.term.name}:</b>"
          text=q.value
          if(pos > max_pre_char)
            text = "..."+text[pos-max_pre_char, (text.length-(pos-max_pre_char))]
          end    
          text.gsub!(/(.{1,#{max_line_char}})( +|$\n?)|(.{1,#{max_line_char}})/,"\\1\\3\n")
          text = truncate(text, :length => 70)
          match += highlight(text, params[:query], :highlighter => '<b class="darkred">\1</b>')
        end
      end

      type = feature.display_name
      if(feature.locus_tag)
        type += ":"+feature.locus_tag.value
      elsif (feature.gene)
        type += ":"+feature.gene.value
      end 

      data.push( {
        :id => feature.id.to_s,
        :type => type,
        :bioentry => feature.bioentry.display_name,
        :bioentry_id => feature.bioentry_id,
        :start => feature.locations.first.start_pos,
        :end => feature.locations.last.end_pos,
        :match => match,
        :reload_url => bioentries_path                             
        })
      end
      render :json  => {
        :success => true,
        :count => features.size,
        :rows => data
      }
  end
  
end