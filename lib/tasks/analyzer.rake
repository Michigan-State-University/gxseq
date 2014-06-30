# Adapted From:
# http://blog.netzmeister-st-pauli.com/post/26764538662/ruby-code-analyzing
# https://github.com/andywenk/ruby_code_analyzer_rake_tasks/
require 'rubygems'
require 'reek/rake/task'

Reek::Rake::Task.new do |t|
  t.source_files = "app"
  t.verbose = false
  t.fail_on_error = false
end

begin
  require 'cane/rake_task'

  desc "Run cane to check quality metrics"
  Cane::RakeTask.new(:cane) do |cane|
    cane.abc_max = 20
    #cane.add_threshold 'coverage/covered_percent', :>=, 99
    cane.no_style = true
    cane.abc_exclude = %w(Foo::Bar#some_method)
  end

  task :default => :cane
rescue LoadError
  warn "cane not available, quality task not provided."
end

namespace :analyzer do
  desc "run all code analyzing tools (reek, rails_best_practices, flog, flay)"
  task :all => [:reek, :rails_best_practices, :flog, :flay, :cane] do
    puts 'have been running all code analyzing tools'
  end

  desc "run reek and find code smells"
  task :reek do
    puts 'Running reek and find code smells'
    Rake::Task['reek'].invoke
  end

  desc "run rails_best_practices and inform about found issues"
  task :rails_best_practices do
    puts 'Running rails_best_practices and inform about found issues'
    puts `rails_best_practices app`
  end

  desc "run flog and find the most tortured code"
  task :flog do
    puts 'Running flog and find the most tortured code'
    sh 'flog -cad app/models/*.rb'
  end

  desc "run flay and analyze code for structural similarities"
  task :flay do
    puts 'Running flay and analyze code for structural similarities'
    sh 'flay app/*'
  end
  
  desc "Run cane to check quality metrics"
  task :cane do
    puts 'Running cane to check quality metrics'
    Rake::Task['cane'].invoke
  end
end