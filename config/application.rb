require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module GenomeSuite
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    #{config.root}/app/models/biosql
    #{config.root}/app/models/biosql/features
    config.autoload_paths += %W[
      #{config.root}/app/models/experiments
      #{config.root}/app/models/experiments/chip
      #{config.root}/app/models/experiments/variants
      #{config.root}/app/models/experiments/assets
      #{config.root}/app/models/experiments/modules
      #{config.root}/app/models/tracks
      #{config.root}/lib/modules
    ]
    # Exception Notifier Gem
    config.middleware.use ::ExceptionNotifier,
      :email_prefix => "GenomeSuite-Errors:",
      :sender_address => %w{gs-notifier@gs.glbrc.org},
      :exception_recipients => APP_CONFIG[:admin_email]
      
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
