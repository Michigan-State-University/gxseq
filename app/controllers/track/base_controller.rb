class Track::BaseController < ApplicationController
  
  def authorize_sample
    @sample = Sample.find(params[:sample])
    authorize! :read, @sample
  end
  
  def authorize_bioentry
    @bioentry = Biosql::Bioentry.find(params[:bioentry])
    authorize! :read, @bioentry
  end
end