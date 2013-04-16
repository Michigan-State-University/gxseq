class GenomesController < ApplicationController
  def index
     @species = Biosql::Taxon.with_species_genomes.accessible_by(current_ability).order "taxon_name.name ASC"
     @biodatabase = Biosql::Biodatabase.find_by_biodatabase_id(params[:biodatabase_id])||Biosql::Biodatabase.first
  end
end