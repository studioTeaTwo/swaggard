require_relative '../swagger/definition'
require_relative '../swagger/property'

module Swaggard
  module Parsers
    class Models

      def run(yard_objects)
        definitions = []
        properties = []
        alias_names = []

        yard_objects.each do |yard_object|
          next unless yard_object.type == :class

          definition = nil
          alias_name = Struct.new(:original, :alias)

          yard_object.tags.each do |tag|
            if tag.tag_name == 'name'
              definition = Swagger::Definition.new(tag.text)
              alias_names << alias_name.new(yard_object.path, tag.text)
            else
              property = Swagger::Property.new(tag)
              properties << property
            end
          end

          definition = Swagger::Definition.new(yard_object.path) if definition.nil?
          definition.add_property(properties) unless properties.empty?
          definitions << definition
        end

        return definitions, alias_names
      end

    end
  end
end