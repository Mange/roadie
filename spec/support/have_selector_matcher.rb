RSpec::Matchers.define :have_selector do |selector|
  match { |document| !document.css(selector).empty? }
  failure_message { "expected document to #{name_to_sentence}#{expected_to_sentence}"}
  failure_message_when_negated { "expected document to not #{name_to_sentence}#{expected_to_sentence}"}
end

