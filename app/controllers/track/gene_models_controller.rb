class Track::GeneModelsController < Track::BaseController
  before_filter :authorize_sample, :only => [:search]
  def syndicate
    # TODO: Update syndication display for gene models.
    render :json  => {
       :success => true,
       :data => {
          :institution => {
             :name => "GLBRC",
             :url => "http:\/\/www.glbrc.org\/",
             :logo => ""
          },
          :engineer => {
             :name => "",
             :email => ""
          },
          :service => {
             :title => "GeneModels",
             :species => "",
             :access => "",
             :version => "",
             :format => "",
             :server => "",
             :description => "GeneModels description"
          }
       }
    }
  end
  
  def range
    my_data = GeneModel.get_track_data(params[:left],params[:right],params[:bioentry],500) 
    render :json => {
      :success => true,
      :data => my_data
    }
  end
  
  def show
    begin
      @gene_model = GeneModel.find_by_id(params[:id]) || Biosql::Feature::Seqfeature.find_by_id(params[:id]).gene_model
      authorize! :read, @gene_model
      @cds = @gene_model.cds
      @gene = @gene_model.gene
      @mrna = @gene_model.mrna
      @ontologies = Biosql::Term.annotation_ontologies
      render :partial => "biosql/feature/genes/info.json"
    rescue => e
      render :json => {
        :success => false,
        :message => "Not Found"
      }
      logger.info "\n\n#{$!}\n\n#{e.backtrace.join("\n")}"
    end
  end
  
  include ActionView::Helpers::TextHelper
  def search
    #TODO: rewrite gene model search using Sunspot
    bioentry_ids = @bioentry.assembly.bioentries.map(&:id)
    data = []

    if(params[:query] && !params[:query].blank?)
      query = params[:query].upcase
      qualifiers = Biosql::SeqfeatureQualifierValue.limit(1000).includes([:term,:seqfeature]).where{seqfeature.bioentry_id.in bioentry_ids}.where{seqfeature.display_name.in GeneModel.seqfeature_types }.where{term.name.not_in(Biosql::Feature::Seqfeature.excluded_search_terms)}.where{upper(value)=~"%#{query}%"}
      ids = qualifiers.collect{|q|q.seqfeature.id}
      gene_models = GeneModel.where{(cds_id.in ids) | (mrna_id.in ids) | (gene_id.in ids)}.includes{[gene.qualifiers, cds.qualifiers, mrna.qualifiers]}.paginate({:page => params[:page],:per_page => params[:limit]})
    else
      gene_models = GeneModel.where{bioentry_id.in bioentry_ids}.order(:bioentry_id, :locus_tag).includes{[gene.qualifiers, cds.qualifiers, mrna.qualifiers]}.paginate({:page => params[:page],:per_page => params[:limit]})
    end
    # Collect the data and matching result
    gene_models.each do |gene_model|
      info = "<br/>"
      match = ""
      max_pre_char = 35
      max_line_char = 35
      max_total_char = 100
      if(query)
        ["gene","cds","mrna"].each do |feature|
          if fea = gene_model.send(feature)
            fea.qualifiers.each do |q|
              # don't match non-search terms
              next if(Biosql::Feature::Seqfeature.excluded_search_terms.include?(q.term.name))
              # avoid repeats
              next if(q.term.name=='locus_tag'||q.term.name=='gene') unless feature =='gene'
              # highlight the first matching qualifier for this feature
              if(pos = q.value(false).upcase=~(/#{params[:query].upcase}/))
                match = "<b>#{q.term.name}:</b>"
                text=q.value(false)
                if(pos > max_pre_char)
                  text = "..."+text[pos-max_pre_char, (text.length-(pos-max_pre_char))]
                end    
                text.gsub!(/(.{1,#{max_line_char}})( +|$\n?)|(.{1,#{max_line_char}})/,"\\1\\3\n")
                text = truncate(text, :length => 70)
                match += highlight(text, params[:query], :highlighter => '<b class="darkred">\1</b>')
                break
              end
            end
          end
        end
      end
      data.push( {
        :id => gene_model.id.to_s,
        :type => gene_model.display_name,
        :bioentry => gene_model.bioentry.display_name,
        :bioentry_id => gene_model.bioentry_id,
        :start => gene_model.start_pos,
        :end => gene_model.end_pos,
        :match => match,
        :reload_url => bioentries_path                         
      })
    end
    # render the match
    render :json  => {
      :success => true,
      :count => gene_models.total_entries,
      :rows => data
    }
  end
  
end