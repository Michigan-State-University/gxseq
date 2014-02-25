class AssetsController < ApplicationController
  load_and_authorize_resource
  def show
  end
  def download
    begin
      send_file @asset.data.path
    rescue => e
      flash[:error]="Error sending file"
      server_error e, "error"
      redirect_to asset_url(@asset)
    end
  end
end