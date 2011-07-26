class Admin::AdminController < ApplicationController
  def index
    redirect_to new_user_session_path unless current_user.is_admin?
  end
end