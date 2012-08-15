class Db < Thor
  ENV['RAILS_ENV'] ||= 'development'
  require File.expand_path('config/environment.rb')
end


