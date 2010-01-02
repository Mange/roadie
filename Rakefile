# encoding: utf-8
require 'rake'
require 'rake/rdoctask'

begin
  require 'spec/rake/spectask'
rescue LoadError
  begin
    gem 'rspec-rails', '>= 1.0.0'
    require 'spec/rake/spectask'
  rescue LoadError
    puts "RSpec - or one of its dependencies - is not available. Install it with: sudo gem install rspec-rails"
  end
end

NAME = "mail_style"
SUMMARY = %{Making HTML emails a little less painful. Writes css inline and corrects image urls.}
HOMEPAGE = "http://github.com/purify/mail_style"
AUTHOR = "Jim Neath"
EMAIL = "jimneath@googlemail.com"
SUPPORT_FILES = %w(readme.textile)

begin
  gem 'jeweler', '>= 1.0.0'
  require 'jeweler'

  Jeweler::Tasks.new do |t|
    t.name = NAME
    t.summary = SUMMARY
    t.email = EMAIL
    t.homepage = HOMEPAGE
    t.description = SUMMARY
    t.author = AUTHOR

    t.require_path = 'lib'
    t.files = SUPPORT_FILES << %w(Rakefile) << Dir.glob(File.join(*%w[{lib,spec} ** *]).to_s)
    t.extra_rdoc_files = SUPPORT_FILES

    t.add_dependency 'actionmailer', '>= 1.2.3'
    t.add_dependency 'nokogiri', '>= 1.0.0'
    t.add_dependency 'css_parser', '>= 1.0.0'

    t.add_development_dependency 'rspec-rails', '>= 1.2.6'
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler - or one of its dependencies - is not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end

desc "Default: Run specs."
task :default => :spec

desc "Generate documentation for the #{NAME} plugin."
Rake::RDocTask.new(:rdoc) do |t|
  t.rdoc_dir = 'rdoc'
  t.title    = NAME
  t.options << '--line-numbers' << '--inline-source'
  t.rdoc_files.include(SUPPORT_FILES)
  t.rdoc_files.include('lib/**/*.rb')
end

if defined?(Spec)
  desc "Run plugin specs for #{NAME}."
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ["-c"]
  end

  desc "Run plugin specs for #{NAME} with specdoc formatting and colors"
  Spec::Rake::SpecTask.new('specdoc') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ["--format specdoc", "-c"]
  end
end
