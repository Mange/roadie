RSpec::Matchers.define :have_styling do |rules|
  normalized_rules = StylingExpectation.new(rules)

  chain(:at_selector) { |selector| @selector = selector }
  match { |document|
    @selector ||= 'body > *:first'
    normalized_rules == styles_at_selector(document)
  }

  description {
    "have styles #{normalized_rules.inspect} at selector #{@selector.inspect}"
  }

  failure_message { |document|
    "expected styles at #{@selector.inspect} to be:\n#{normalized_rules}\nbut was:\n#{styles_at_selector(document)}"
  }

  failure_message_when_negated {
    "expected styles at #{@selector.inspect} to not be:\n#{normalized_rules}"
  }

  def styles_at_selector(document)
    expect(document).to have_selector(@selector)
    StylingExpectation.new document.at_css(@selector)['style']
  end
end

class StylingExpectation
  def initialize(styling)
    case styling
    when String then @rules = parse_rules(styling)
    when Array then @rules = styling
    when Hash then @rules = styling.to_a
    when nil then @rules = []
    else fail "I don't understand #{styling.inspect}!"
    end
  end

  def ==(other)
    rules == other.rules
  end

  def to_s() rules.to_s end

  protected
  attr_reader :rules

  private
  def parse_rules(css)
    css.split(';').map { |property| parse_property(property) }
  end

  def parse_property(property)
    rule, value = property.split(':', 2).map(&:strip)
    [rule, normalize_quotes(value)]
  end

  # JRuby's Nokogiri encodes quotes
  def normalize_quotes(string)
    string.gsub '%22', '"'
  end
end
