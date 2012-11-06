guard 'rspec', :rvm => ['1.9.3', 'jruby-head', 'ruby-1.8.7-p358'] do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }

  watch(%r{spec/support/.*\.rb}) { "spec" }
  watch('spec/spec_helper.rb')   { "spec" }
end

