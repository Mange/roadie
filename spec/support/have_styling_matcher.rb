RSpec::Matchers.define :have_styling do |rules|
  @selector = 'body > *:first'

  chain :at_selector do |selector|
    @selector = selector
  end

  match do |document|
    if rules.nil?
      parsed_styles(document).blank?
    else
      rules.to_a.should == parsed_styles(document)
    end
  end

  describe { "have styles #{rules.inspect} at selector #{@selector.inspect}" }
  failure_message_for_should { |document| "expected styles at #{@selector.inspect} to be #{rules.inspect} but was #{parsed_styles(document).inspect}" }
  failure_message_for_should_not { "expected styles at #{@selector.inspect} to not be #{rules.inspect}" }

  def parsed_styles(document)
    parse_styles(element_style(document))
  end

  def element_style(document)
    node = document.css(@selector).first
    node && node['style']
  end

  def parse_styles(styles)
    return [] if styles.blank?
    styles.split(';').inject([]) do |array, item|
      array << item.split(':', 2).map(&:strip)
    end
  end
end

