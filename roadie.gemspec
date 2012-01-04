# roadie.gemspec
# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require 'roadie/version'

Gem::Specification.new do |s|
  s.name        = 'roadie'
  s.version     = Roadie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Magnus Bergmark']
  s.email       = ['magnus.bergmark@gmail.com']
  s.homepage    = 'http://github.com/Mange/roadie'
  s.summary     = %q{Making HTML emails comfortable for the Rails rockstars}
  s.description = %q{Roadie tries to make sending HTML emails a little less painful in Rails 3 by inlining stylesheets and rewrite relative URLs for you.}

  s.add_dependency 'nokogiri', '>= 1.4.4'
  s.add_dependency 'css_parser'
  s.add_dependency 'actionmailer', '> 3.0.0', '< 3.3.0'
  s.add_dependency 'sprockets'

  s.add_development_dependency 'rails'
  s.add_development_dependency 'rspec-rails'

  s.add_development_dependency 'appraisal'

  s.extra_rdoc_files = %w[README.md Changelog.md]
  s.require_paths = %w[lib]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
end

