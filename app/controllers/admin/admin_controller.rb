class Admin::AdminController < ApplicationController
  before_filter :check_admin
  def check_admin
    unless current_user.try(:is_admin?)
      flash[:error] = "Not Authorized!"
      redirect_to root_path
      return
    end
  end
end