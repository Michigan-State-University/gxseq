class TaxonVersionsController < ApplicationController

  before_filter :find_taxon_version, :only => [:show, :edit, :update]

  def index
    respond_to do |wants|
      wants.html {@bioentry_species = Taxon.in_use_species.includes(:scientific_name, :taxon_versions => [:taxon => [:taxon_names]])}
      wants.json {
        #begin
          query = params[:query].upcase
          t_version = TaxonVersion.find(params[:taxon_version_id])
          bioentries = Bioentry.includes{[taxon_version,source_features.qualifiers.term]}
          bioentries = bioentries.where{ ( (taxon_version.id == my{t_version.id}) & ( (upper(description) =~ "%#{query}%") | (upper(accession) =~ "%#{query}%") | (upper(source_features.qualifiers.value) =~ "%#{query}%") ) )}
          bioentries = bioentries.paginate(:page => params[:page],:per_page => params[:limit])
          bioentries = bioentries.order('accession desc')
          
          data=[]
          bioentries.each do |entry|
            b = Bioentry.find(entry.id, :include => [:taxon_version,[:source_features => [:qualifiers => :term]]] )
            #add the datapoint
            data.push( {
              :id => b.id,
              :accession => b.accession,
              :name => b.display_name,
              :length => b.biosequence_without_seq.length,
              :reload_url => bioentries_path
            })
          end
          # render the match
          render :json  => {
            :success => true,
            :count => bioentries.total_entries,
            :rows => data
          }
        #rescue
          # logger.info "\n\n#{$!}\n#{caller.join("\n")}\n\n"
          # render :json => {
          #   :succes => false
          # }
        #end
      }
    end
  end
  
  def show  
  end

  def edit
  end

  def update
    respond_to do |wants|
      if @taxon_version.update_attributes(params[:taxon_version])
        flash[:notice] = 'TaxonVersion was successfully updated.'
        wants.html { redirect_to(@taxon_version) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  private
    def find_taxon_version
      @taxon_version = TaxonVersion.find(params[:id])
    end

end
