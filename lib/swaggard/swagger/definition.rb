module Swaggard
  module Swagger
    class Definition

      attr_reader :id

      def initialize(id)
        @id = id
        @properties = []
      end

      def add_property(property)
        property.kind_of?(Array) ? @properties.concat(property) : @properties << property
      end

      def to_doc
        {
          'type'        => 'object',
          'required'    => [],
          'properties'  => Hash[@properties.map { |property| [property.id, property.to_doc] }]
        }
      end

    end
  end
end