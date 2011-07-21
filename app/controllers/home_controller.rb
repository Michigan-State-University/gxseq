class HomeController < ApplicationController
  def index
    logger.info "\n\n#{user_signed_in?}\n\n"
    logger.info "\n\n#{current_user.inspect}\n\n"
  end
end