RSpec::Matchers.define :have_selector do |selector|
  match { |document| !document.css(selector).empty? }
  failure_message { "expected document to #{name_to_sentence}#{to_sentence selector}"}
  failure_message_when_negated { "expected document to not #{name_to_sentence}#{to_sentence selector}"}
end

