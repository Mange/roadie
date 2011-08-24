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
      styles.split(';').inject([]) do |array, item|
        array << item.split(':', 2).map(&:strip)
      end
    end
  end
end
