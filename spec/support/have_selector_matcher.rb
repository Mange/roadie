RSpec::Matchers.define :have_selector do |selector|
  match { |document| document.css(selector).present? }
  failure_message_for_should { "expected document to #{name_to_sentence}#{expected_to_sentence}"}
  failure_message_for_should_not { "expected document to not #{name_to_sentence}#{expected_to_sentence}"}
end

