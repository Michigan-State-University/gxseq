source 'http://rubygems.org'

gem 'rails', '3.0.9'

# Choose your database adapter
group :production do
  gem 'activerecord-oracle_enhanced-adapter'
  gem 'ruby-oci8'
end
group :development, :test do
  gem 'mysql2', '~> 0.2.0'
  gem 'railroady'
  gem 'ruby-debug19'
  gem 'annotate', ">=2.5.0.pre1"
  # Code analyzers
  gem 'reek'
  gem 'rails_best_practices'
  gem 'flay'
  gem 'flog'
end

gem 'acts_as_api', '~>0.3'
gem 'xmlparser'
gem 'bio', '~> 1.4.3'
gem 'bio-samtools', '~>0.4', :git => 'git://github.com/throwern/bioruby-samtools.git'
gem 'composite_primary_keys', '=3.1.10', :path => 'vendor/gems/composite_primary_keys-3.1.10'
gem 'daemons', '1.1.4'
gem 'delayed_job', '~> 3'
gem 'delayed_job_active_record'
gem 'devise', '~> 1.3.4'
gem "devise_ldap_authenticatable", :git => 'git://github.com/clyfe/devise_ldap_authenticatable.git'
gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'
gem 'formtastic', "~> 2.2.1"
gem 'paper_trail', '~>2'
gem 'paperclip', '~> 2.3'
gem 'squeel', '~>0.9'
gem 'thor', '~> 0.14.6'
gem 'will_paginate', '~>3'
gem 'bio-tabix', '~>0.1'
gem 'bio-ucsc-util', '0.1.2'
#gem 'bio-ucsc-util', :path => '~/gems/bio-ucsc-util'
git 'git://github.com/throwern/sunspot.git' do
  gem 'sunspot'
  gem 'sunspot_rails'
  gem 'sunspot_solr'
end
# gem 'sunspot', :path => '~/gems/sunspot/sunspot'
# gem 'sunspot_rails', :path => '~/gems/sunspot/sunspot_rails'
# gem 'sunspot_solr', :path => '~/gems/sunspot/sunspot_solr'
# gem 'sunspot_rails'
# gem 'sunspot_solr'
gem 'progress_bar'
gem 'cancan'
gem 'rails3-jquery-autocomplete'
gem 'newrelic_rpm'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'
