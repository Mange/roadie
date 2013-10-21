module SpecHelpers
  class << self
    def parse_styling(styles)
      styles.split(';').map { |style| parse_style(style) }
    end

    private
    def parse_style(style)
      rule, value = style.split(':', 2).map(&:strip)
      [rule, value]
    end
  end
end
