# frozen_string_literal: true

RSpec::Matchers.define :have_selector do |selector|
  match { |document| !document.css(selector).empty? }
  failure_message { "expected document to have selector #{selector.inspect}"}
  failure_message_when_negated { "expected document to not have selector #{selector.inspect}"}
end

