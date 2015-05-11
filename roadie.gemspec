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
  s.summary     = %q{Making HTML emails comfortable for the Ruby rockstars}
  s.description = %q{Roadie tries to make sending HTML emails a little less painful by inlining stylesheets and rewriting relative URLs for you.}
  s.license     = "MIT"

  s.required_ruby_version = ">= 1.9"

  s.add_dependency 'nokogiri', '>= 1.5.0', '< 1.7.0'
  s.add_dependency 'css_parser', '~> 1.3.4'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.0'
  s.add_development_dependency 'webmock', '~> 1.21.0'

  s.extra_rdoc_files = %w[README.md Changelog.md]
  s.require_paths = %w[lib]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
end

