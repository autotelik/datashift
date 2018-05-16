# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   You can build a FLow for import or export within a YAML config file
#
#             It supports a simple DSL in below format.
#
#             SYNTAX :
#               Indentation, usually 2 spaces, or a 2 space TAB, is very important
#               <> are used to illustrate the elements that accept free text
# Nodes :
#
#   Since the order is important, i.e should be preserved so your columns come out in defined order a sequence
#   should be used
#
# Node :
#
# Each Node can have these elements
#
#   :heading:
#       source:  The column header
#       destination:  The column header
#
#   :operator:   How to get the data - for export would be the method call on the model
#
# EXAMPLE:
#
# data_flow_schema:
#   Project:
#     nodes:
#       - project:
#         heading:
#           source: "title"
#           destination: "Title"
#         operator: title
#
#       - project_owner_budget:
#         heading:
#           destination: "Budget"
#         operator: owner.budget
#
require 'erubis'

module DataShift

  class DataFlowSchema

    include DataShift::Logging

    attr_reader :nodes, :raw_data, :yaml_data

    def initialize
      @nodes = DataShift::NodeCollection.new
    end

    # @headers=
    # <DataShift::Header:0x00000004bc37f8
    #  @presentation="status_str",
    #  @source="status_str">],

    def headers
      # TODO: fix doc context so it can be created 'empty' i.e without AR klass, and always has empty headers
      @nodes.doc_context.try(:headers) || []
    end

    def sources
      @nodes.collect(&:method_binding).collect(&:source)
    end

    def create_node_collections(klass, doc_context: nil)
      context = doc_context || DocContext.new(klass)
      @nodes = DataShift::NodeCollection.new(doc_context: context)
      @nodes
    end

    # Build the node collection from a Class, that is for each operator in scope
    # create a method binding and a node context, and add to collection.
    #
    def prepare_from_klass( klass, doc_context = nil )

      @nodes = create_node_collections(klass, doc_context: doc_context)

      @nodes.headers = Headers.klass_to_headers(klass)

      klass_to_model_methods( klass ).each do |mm|
        # headers define what nodes are actually in scope
        next unless @nodes.headers.header?(mm)

        i = @nodes.headers.index(mm)

        binding = MethodBinding.new(mm.operator, mm, idx: i)  # TOFIX - why need to pass in both mm.operator AND mm ??

        # TODO: - do we really need to pass in the doc context when parent nodes already has it ?
        @nodes << DataShift::NodeContext.new(@nodes.doc_context, binding, i, nil)
      end

      @nodes
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_model_methods(klass)

      op_types_in_scope = DataShift::Configuration.call.op_types_in_scope

      collection = ModelMethods::Manager.catalog_class(klass)

      model_methods = []

      if collection

        collection.each { |mm| model_methods << mm if(op_types_in_scope.include? mm.operator_type) }

        remove = DataShift::Transformation::Remove.new

        remove.unwanted_model_methods model_methods
      end

      model_methods
    end

    # Supports YAML with optional ERB snippets
    #
    # See Config generation or lib/datashift/templates/import_export_config.erb for full syntax
    #
    # Returns  DataShift::NodeCollection
    #
    def prepare_from_file(yaml_file, locale_key = 'data_flow_schema')
      @raw_data = ERB.new(File.read(yaml_file)).result

      yaml = Configuration.parse_yaml(yaml_file)

      prepare_from_yaml(yaml, locale_key)
    end

    def prepare_from_string(text, locale_key = 'data_flow_schema')
      @raw_data = text
      yaml = YAML.safe_load(raw_data)

      prepare_from_yaml(yaml, locale_key)
    end

    def prepare_from_yaml(yaml, locale_key = 'data_flow_schema')

      @yaml_data = yaml

      raise "Bad YAML syntax  - No key #{locale_key} found in #{yaml}" unless yaml[locale_key]

      locale_section = yaml[locale_key]

      if(locale_section.key?('Global'))
        global_nodes = locale_section.delete('Global')

        [*global_nodes].each do |c|

          # TODO: what is c ?   a list or hash ?
          # if DataShift::Configuration.call.respond_to #{c}=
          # Set the global value e.g
          # DataShift::Configuration.call.force_inclusion_of_columns = [:audio]
        end
      end

      unless locale_section.keys.present?
        logger.warn('No class related configuration found in YAML syntax- Nothing to process')
        return DataShift::NodeCollection.new
      end

      class_name = locale_section.keys.first

      klass = MapperUtils.class_from_string_or_raise(class_name)

      klass_section = locale_section[class_name]

      DataShift::Transformation.factory { |f| f.configure_from_yaml(class_name, klass_section) }

      @nodes = create_node_collections(klass)

      if(klass_section && klass_section.key?('nodes'))

        yaml_nodes = klass_section['nodes']

        logger.info("Read Data Schema Nodes: #{yaml_nodes.inspect}")

        unless(yaml_nodes.is_a?(Array))
          Rails.logger.error('Bad syntax in flow schema YAML - Nodes should be a sequence')
          raise 'Bad syntax in flow schema YAML - Nodes should be a sequence'
        end

        # for operator and type
        model_method_mgr = ModelMethods::Manager.catalog_class(klass)

        yaml_nodes.each_with_index do |keyed_node, i|

          unless(keyed_node.keys.size == 1)
            raise ConfigFormatError, "Bad syntax in flow schema YAML - Section #{keyed_node} should be keyed hash"
          end

          # data_flow_schema:
          #   Project:
          #     nodes:
          #       - project:
          #           source: "title"           # source of data, defaults to node name (project) if not specified
          #           presentation: "Title"     # e.g for export headers
          #           operator: title
          #           operator_type: has_many
          #
          logger.info("Node Data: #{keyed_node.inspect}")

          node = keyed_node.keys.first

          section = keyed_node.values.first || {}

          # TODO: - layout with heading is verbose for no benefit - defunct, simply node.source, node.presentation
          source = section.fetch('heading', {}).fetch('source', nil)

          # Unless a specific source mentioned assume the node is the source
          source ||= section.fetch('source', node)

          presentation = section.fetch('presentation', nil)

          @nodes.headers.add(source, presentation: presentation)

          if(section['operator'])
            # Find the domain model method details
            # byebug
            model_method = model_method_mgr.search(section['operator'])

            unless model_method
              operator_type = section['operator_type'] || :method

              # TODO: validate type ? guess we expect one of ModelMethod.supported_types_enum
              model_method = model_method_mgr.insert(section['operator'], operator_type)
              # TODO: - This index could be hard coded by the user in YAML or we try to derive it from the headers
              # byebug
              method_binding = MethodBinding.new(source, model_method, idx: section['index'])
            end
          end

          # Now ensure we bind source/header(and index) to the method tht performs assignment of inbound datum to the model
          #
          # TOFIX - This is a bug waiting to happen right ? i is not coming from the headers
          # so chances are user hasn't made config indexed as per headers
          # index could be hard coded by the user in YAML or we try to derive it from the headers via the binder ???
          method_binding ||= MethodBinding.new(source, model_method, idx: i)

          node_context = DataShift::NodeContext.new(@nodes.doc_context, method_binding, i, nil)

          @nodes << node_context
        end
      end

      @nodes
    end

  end
end
