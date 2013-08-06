guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/roadie/(.+)\.rb$})     { |m| ["spec/lib/roadie/#{m[1]}_spec.rb", "spec/#{m[1]}_spec.rb"] }

  watch(%r{spec/support/.*\.rb}) { "spec" }
  watch('spec/spec_helper.rb')   { "spec" }
end

