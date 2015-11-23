module Roadie
  class StyleAttributeBuilder
    def initialize
      @styles = []
    end

    def <<(style)
      @styles << style
    end

    def attribute_string
      Deduplicator.apply(stable_sort(@styles).map(&:to_s)).join(';')
    end

    private
    def stable_sort(list)
      # Ruby's sort is unstable for performance reasons. We need it to be
      # stable, e.g. to preserve order of elements that are compared equal in
      # the sorting.
      # We can accomplish this by using the original array index as a second
      # comparator for when the first one is equal.
      list.each_with_index.sort_by { |item, index| [item, index] }.map(&:first)
    end
  end
end
