require 'json'
require 'yard'

require 'swaggard/api_definition'
require 'swaggard/configuration'
require 'swaggard/engine'

require 'swaggard/parsers/controllers'
require 'swaggard/parsers/models'
require 'swaggard/parsers/routes'

module Swaggard

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Swaggard::Configuration.new
    end

    # Register some custom yard tags
    def register_custom_yard_tags!
      ::YARD::Tags::Library.define_tag('Controller\'s tag',  :tag)
      ::YARD::Tags::Library.define_tag('Object Name', :name)   
      ::YARD::Tags::Library.define_tag('Query parameter', :query_parameter)
      ::YARD::Tags::Library.define_tag('Form parameter',  :form_parameter)
      ::YARD::Tags::Library.define_tag('Body parameter',  :body_parameter)
      ::YARD::Tags::Library.define_tag('Parameter list',  :parameter_list)
      ::YARD::Tags::Library.define_tag('Response class',  :response_class)
      ::YARD::Tags::Library.define_tag('Response Root',  :response_root)
      ::YARD::Tags::Library.define_tag('Response Status',  :response_status)
    end

    def get_doc(host)
      load!

      doc = @api.to_doc
      doc = replace_alias(doc)

      doc['host'] = host if doc['host'].blank?

      doc
    end

    private

    def load!
      @api = Swaggard::ApiDefinition.new

      parse_models
      parse_controllers
    end

    def parse_controllers
      parser = Parsers::Controllers.new

      alias_names = []
      Dir[configuration.controllers_path].each do |file|
        yard_objects = get_yard_objects(file)

        tag, operations, alias_name = parser.run(yard_objects, routes)

        next unless tag

        @api.add_tag(tag)
        operations.each { |operation| @api.add_operation(operation) }
        alias_names.concat(alias_name)
      end
      @api.alias_names.concat(alias_names)
    end

    def routes
      return @routes if @routes

      parser = Parsers::Routes.new
      @routes = parser.run(configuration.routes)
    end

    def parse_models
      parser = Parsers::Models.new

      definitions, alias_names = [], []
      configuration.models_paths.each do |path|
        Dir[path].each do |file|
          yard_objects = get_yard_objects(file)

          definition, alias_name = parser.run(yard_objects)
          definitions.concat(definition)
          alias_names.concat(alias_name)
        end
      end
      @api.definitions = definitions
      @api.alias_names.concat(alias_names)
    end

    def get_yard_objects(file)
      ::YARD.parse(file)
      yard_objects = ::YARD::Registry.all
      ::YARD::Registry.clear

      yard_objects
    end

    def replace_alias(doc)
      unless @api.alias_names.empty?
        str = JSON.generate(doc)
        @api.alias_names.each do |name|
          str.gsub!(/#{name.original}/, name.alias)
        end
        doc = JSON.load(str)
      end
      doc
    end

  end
end
