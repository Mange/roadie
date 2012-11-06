module SpecHelpers
  class << self
    def styling_of_node(node)
      if node and node['style'].present?
        parse_styling(node['style'])
      else
        []
      end
    end

    def parse_styling(styles)
      styles.split(';').map { |style| parse_style(style) }
    end

    private
      def parse_style(style)
        rule, value = style.split(':', 2).map(&:strip)
        [rule, normalize_escaped_quotes(value)]
      end

      def normalize_escaped_quotes(string)
        string.gsub('%22', '"')
      end
  end
end
