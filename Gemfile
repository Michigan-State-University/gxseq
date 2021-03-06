source 'http://rubygems.org'

gem 'rails', '3.0.9'

# production specific settings
group :production do
  #gem 'activerecord-oracle_enhanced-adapter', '1.4.2'
  #gem 'ruby-oci8'
  #gem 'mysql2', '~> 0.2.0'
end
# Development testing and update gems
group :development do
  gem 'sqlite3'
  gem 'annotate', ">=2.5"
  gem 'better_errors'
  gem 'binding_of_caller'
  # Code analyzers and security
  gem 'rails_best_practices'
  gem 'flay'
  gem 'flog'
  gem 'cane'
  gem 'brakeman'
  # Real Time Updates - mac development
  gem 'guard'
  gem 'rb-fsevent', :require => false
  gem 'guard-livereload'
  gem 'cucumber'
end
group :test do
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'simplecov'
  gem 'rspec-rails'
  gem 'rspec'
  gem 'shoulda'
  gem 'capybara'
  gem 'aruba'
  gem 'selenium-webdriver','~> 2.42.0'
  gem 'launchy'
  gem 'json_spec'
end

group :cucumber do
  gem 'cucumber-rails'
end

gem 'reek'
gem 'terminal-table', '~> 1.4.5'
# All the rest
gem 'acts_as_api', '~>0.3'
gem 'xmlparser'
gem 'bio', '~> 1.4.3'
gem 'bio-samtools', '0.5.2', :git => 'git://github.com/throwern/bioruby-samtools.git'
#gem 'bio-samtools', :path => '~/gems/bioruby-samtools'
gem 'composite_primary_keys', '=3.1.10', :path => 'vendor/gems/composite_primary_keys-3.1.10'
gem 'daemons', '1.1.4'
gem 'delayed_job', '~> 3'
gem 'delayed_job_active_record'
gem 'devise', '~> 1.3.4'
gem "devise_ldap_authenticatable", :git => 'git://github.com/clyfe/devise_ldap_authenticatable.git'
gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'
gem 'formtastic', "~> 2.2.1"
gem 'paper_trail', '~>2'
gem 'paperclip', '~> 3.0'
gem 'squeel', '~>0.9'
gem 'thor', '~> 0.14.6'
gem 'will_paginate', '~>3'
gem 'bio-tabix', '1.0.1'
gem 'bio-ucsc-util', '0.1.2'
#gem 'bio-ucsc-util', :path => '~/gems/bio-ucsc-util'
gem 'sunspot', '~> 2.1.1'
gem 'sunspot_rails', '~> 2.1.1'
gem 'sunspot_solr', '~> 2.1.1'
gem 'progress_bar', '~> 1.0.0'
gem 'cancan'
gem 'rails3-jquery-autocomplete'
gem 'acts-as-taggable-on', '~> 2.3.1'
gem 'parallel'
gem 'descriptive-statistics'
gem 'simple-tooltip'
# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'
