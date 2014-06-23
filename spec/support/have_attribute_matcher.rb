RSpec::Matchers.define :have_attribute do |attribute|
  @selector = 'body > *:first'

  chain :at_selector do |selector|
    @selector = selector
  end

  match do |document|
    name, expected = attribute.first
    expected == attribute(document, name)
  end

  description { "have attribute #{attribute.inspect} at selector #{@selector.inspect}" }
  failure_message do |document|
    name, expected = attribute.first
    "expected #{name} attribute at #{@selector.inspect} to be #{expected.inspect} but was #{attribute(document, name).inspect}"
  end
  failure_message_when_negated do |document|
    name, expected = attribute.first
    "expected #{name} attribute at #{@selector.inspect} to not be #{expected.inspect}"
  end

  def attribute(document, attribute_name)
    node = document.css(@selector).first
    node && node[attribute_name]
  end
end

