module Roadie
  # @api private
  # Stores orphan style properties as they are being merged into specific
  # element's "style" attribute.
  class StyleProperties
    attr_reader :properties

    def initialize(properties)
      @properties = properties
    end

    def merge(new_properties)
      StyleProperties.new(properties + properties_of(new_properties))
    end

    def merge!(new_properties)
      @properties += properties_of(new_properties)
    end

    def to_s
      @properties.sort.map(&:to_s).join(";")
    end

    private
    def properties_of(object)
      object.respond_to?(:properties) ? object.properties : object
    end
  end
end
