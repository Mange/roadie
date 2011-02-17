RSpec::Matchers.define :have_styling do |rules|
  chain :at_selector do |selector|
    @selector = selector
  end

  match do |document|
    styles = parsed_styles(document)
    if rules.nil?
      styles.blank?
    else
      rules.to_a.should == parsed_styles(document)
    end
  end

  describe { "have styles #{rules.inspect} at selector #{@selector.inspect}" }
  failure_message_for_should { |document| "expected styles at #{@selector.inspect} to be #{rules.inspect} but was #{parsed_styles(document).inspect}" }
  failure_message_for_should_not { "expected styles at #{@selector.inspect} to not be #{rules.inspect}" }

  def element_styles(document)
    node = document.css(@selector).first
    node && node['style']
  end

  def parsed_styles(document)
    return @parsed_styles if defined?(@parsed_styles)
    if (styles = element_styles(document)).present?
      @parsed_styles = styles.split(';').inject([]) do |styles, item|
        attribute, value = item.split(':', 2)
        styles << [attribute.strip, value.strip]
      end
    else
      @parsed_styles = nil
    end
  end
end

