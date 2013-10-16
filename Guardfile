guard 'rspec', cli: '--format nested' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }

  watch(%r{lib/roadie/rspec/.*\.rb}) { "spec" }

  watch(%r{spec/support/.*\.rb}) { "spec" }
  watch('spec/spec_helper.rb')   { "spec" }
end

