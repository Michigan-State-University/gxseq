class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!
  around_filter :setup_delayed_job_whodunnit
  
  private
  # Thread.current setup from PaperTrail added to delayed job see overrides.rb, controller setup from:
  # http://stackoverflow.com/questions/7896298/safety-of-thread-current-usage-in-rails
  def setup_delayed_job_whodunnit
    Delayed::Backend::ActiveRecord::Job.whodunnit = current_user ? current_user.id : nil
    begin
      yield
    ensure
      Delayed::Backend::ActiveRecord::Job.whodunnit = nil
    end
  end
end
