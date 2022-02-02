# frozen_string_literal: true

require "bundler/setup"

Bundler::GemHelper.install_tasks

desc "Run specs"
task :spec do
  sh "bundle exec rspec -f progress"
end

desc "Default: Run specs"
task default: :spec
