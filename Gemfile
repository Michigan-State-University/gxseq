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
end

gem 'acts_as_api', '~>0.3'
gem 'bio', '~> 1.4.2'
gem 'bio-samtools', '~>0.4', :git => 'git://github.com/throwern/bioruby-samtools.git'
#gem 'bio-samtools', '~>0.4', :path => '~/gems/bioruby-samtools'
gem 'composite_primary_keys', '=3.1.10', :path => 'vendor/gems/composite_primary_keys-3.1.10'
gem 'daemons', '1.1.4'
gem 'delayed_job', '~> 3'
gem 'delayed_job_active_record'
gem 'devise', '~> 1.3.4'
gem "devise_ldap_authenticatable", :git => 'git://github.com/clyfe/devise_ldap_authenticatable.git'
gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'
gem 'formtastic', '~>2'
gem 'paper_trail', '=2.2.9', :git => 'git://github.com/throwern/paper_trail.git'
gem 'paperclip', '~> 2.3'
gem 'squeel', '~>0.9'
gem 'thor', '~> 0.14.6'
gem 'will_paginate', '~>3'
gem 'bio-tabix', '0.1.3'
# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'
