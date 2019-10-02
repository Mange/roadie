# frozen_string_literal: true

RSpec::Matchers.define :have_xpath do |xpath|
  match { |document| !document.xpath(xpath).empty? }
  failure_message { "expected document to have xpath #{xpath.inspect}"}
  failure_message_when_negated { "expected document to not have xpath #{xpath.inspect}"}
end

