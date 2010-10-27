# encoding: utf-8
require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'

require 'rake/rdoctask'
require 'rspec/core/rake_task'

NAME = "mail_style"
EXTRA_RDOC_FILES = %w[readme.textile]
Jeweler::Tasks.new do |t|
  t.name = NAME
  t.summary = %{Making HTML emails a little less painful}
  t.email = "jimneath@googlemail.com"
  t.homepage = "http://github.com/purify/mail_style"
  t.description = %{Making HTML emails a little less painful. Writes css inline and corrects image urls.}
  t.author = "Jim Neath"

  t.require_path = 'lib'
  t.files = %w(Rakefile) + EXTRA_RDOC_FILES + Dir.glob(File.join(*%w[{lib,spec} ** *]).to_s)
  t.extra_rdoc_files = EXTRA_RDOC_FILES
  
  # dependencies defined in Gemfile
end

Jeweler::RubygemsDotOrgTasks.new

desc "Generate documentation for the #{NAME} plugin."
Rake::RDocTask.new(:rdoc) do |t|
  t.rdoc_dir = 'rdoc'
  t.title    = NAME
  t.options << '--line-numbers' << '--inline-source'
  t.rdoc_files.include(EXTRA_RDOC_FILES)
  t.rdoc_files.include('lib/**/*.rb')
end

desc "Run plugin specs for #{NAME}."
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ["-c"]
end

desc "Run plugin specs for #{NAME} with specdoc formatting and colors"
RSpec::Core::RakeTask.new('specdoc') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ["--format specdoc", "-c"]
end

desc "Default: Run specs."
task :default => :spec
