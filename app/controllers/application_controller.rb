class ApplicationController < ActionController::Base
  protect_from_forgery
  #before_filter :authenticate_user!
  around_filter :setup_delayed_job_whodunnit
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Access Denied"
    redirect_to current_user || login_path #root_url
  end
  
  # We want to direct logins to the user account page if no other path is already set
  def after_sign_in_path_for(resource)
   stored_location_for(resource) || current_user
  end
  
  protected
  # convenience method to send exception message
  def server_error(exception, message)
    ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
  end
  
  private
  # Thread.current setup from PaperTrail added to delayed job see overrides.rb, controller setup from:
  # http://stackoverflow.com/questions/7896298/safety-of-thread-current-usage-in-rails
  # Allows tracking user submission of jobs
  def setup_delayed_job_whodunnit
    Delayed::Backend::ActiveRecord::Job.whodunnit = current_user ? current_user.id : nil
    begin
      yield
    ensure
      Delayed::Backend::ActiveRecord::Job.whodunnit = nil
    end
  end
end
