require_relative '../swagger/operation'
require_relative '../swagger/tag'

module Swaggard
  module Parsers
    class Controllers

      def run(yard_objects, routes)
        tag = nil
        operations = []
        alias_names = []

        yard_objects.each do |yard_object|
          if yard_object.type == :class
            tag = Swagger::Tag.new(yard_object)
          elsif tag && yard_object.type == :method

            alias_name = Struct.new(:original, :alias)
            yard_object.tags.each do |_tag|
              alias_names << alias_name.new(createOriginalPath(yard_object, tag), _tag.text) if _tag.tag_name == 'name'
            end
            
            operation = Swagger::Operation.new(yard_object, tag, routes)
            operations << operation if operation.valid?
          end
        end

        return unless operations.any?

        return tag, operations, alias_names
      end

      private

      def createOriginalPath(yard_object, tag)
        "#{tag.controller_class.to_s}.#{yard_object.name}_body"
      end

    end
  end
end

