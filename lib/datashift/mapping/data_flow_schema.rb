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

    attr_reader :configuration, :nodes

    def initialize
      @nodes = DataShift::NodeCollection.new
    end

    def sources
      @nodes.collect(&:method_binding).collect(&:source)
    end

    def prepare_from_klass( klass )

      @nodes =  DataShift::NodeCollection.new

      klass_to_model_methods( klass ).each_with_index do |mm, i|
        puts "DataFlowSchema - #{mm.operator}"

        binding = MethodBinding.new(mm.operator, i, mm)

        @nodes << DataShift::NodeContext.new( DocContext.new(klass), binding, i, nil)
      end

      @nodes
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_model_methods(klass)

      op_types_in_scope = DataShift::Configuration.call.op_types_in_scope

      puts "DataFlowSchema - OpTypesInScope : #{op_types_in_scope}"

      collection = ModelMethods::Manager.catalog_class(klass)

      model_methods = []

      if collection

        collection.each { |mm| model_methods << mm if(op_types_in_scope.include? mm.operator_type) }

        remove = DataShift::Transformer::Remove.new

        remove.unwanted_model_methods model_methods
      end

      model_methods

    end

    def prepare_from_file(file_name, locale_key = "data_flow_schema")
      yaml = YAML.load( File.read(file_name) )

      prepare_from_yaml(yaml, locale_key)
    end

    def prepare_from_string(text, locale_key = "data_flow_schema")
      yaml = YAML.load(text)

      prepare_from_yaml(yaml, locale_key)
    end

    def prepare_from_yaml(klass, yaml, locale_key = "data_flow_schema")

      @nodes = NodeCollection.new

      raise RuntimeError.new("Bad YAML syntax  - No key #{locale_key} found in #{yaml}") unless yaml[locale_key]

      klass = yaml[locale_key][klass]

      yaml_nodes =yaml[locale_key][klass]['nodes']

      logger.info("Nodes: #{nodes.inspect}")

      unless(yaml_nodes.is_a?(Array))
        Rails.logger.error("Bad syntax in flow schema YAML - Nodes should be a sequence")
        raise RuntimeError, "Bad syntax in flow schema YAML - Nodes should be a sequence"
      end

      nodes = []

      # The over all doc context
      doc = DataShift::DocContext.new( klass )

      yaml_nodes.each_with_index do |section, i|

        unless(section.keys.size == 1)
          Rails.logger.error("Bad syntax in flow schema YAML - Section should be keyed hash")
          raise RuntimeError, "Bad syntax in flow schema YAML - Section should be keyed hash"
        end

        # data_flow_schema:
        #   Project:
        #     nodes:
        #       - project:
        #         heading:
        #           source: "title"
        #           destination: "Title"
        #         operator: title
        #         operator_type: has_many
        #
        #       - project_owner_budget:
        #         heading:
        #           destination: "Budget"
        #         operator: owner.budget
        #
        logger.info("Node Data: #{section.inspect}")

        # type one of ModelMethod.supported_types_enum
        operator = Operator.new(data['operator'], :method)

        model_method = ModelMethod.new( klass,operator, section['operator_type'])

        method_binding = MethodBinding.new(section['heading']['source'], i, model_method)

        doc.headers.add( section['heading']['source'] )

        node = DataShift::NodeContext.new(doc, method_binding, i, nil)

        nodes << node
      end

      nodes
    end

    private

    attr_accessor :current_review_object

    attr_accessor :model_object

    def row_to_node_collection(review_object, row)
      # The section name, can be used as the state, for linking whole section, rather than at field level
      link_state = row[:link_state] || current_section
      link_title = row[:link_title]

      @current_review_object = review_object

      # The review partial can support whole objects, or low level data from method call defined in the DSL
      if(row[:method].blank?)
        node_collection.add(row[:title], review_object, link_state.to_s, link_title)
      else
        # rubocop:disable Style/IfInsideElse
        if(review_object.respond_to?(:each))
          review_object.each do |o|
            @current_review_object = o
            node_collection.add(row[:title], send_chain(row[:method]), link_state.to_s, link_title)
          end
        else
          node_collection.add(row[:title], send_chain(row[:method]), link_state.to_s, link_title)
        end

      end
    end

    def find_association(method_chain)
      arr = method_chain.to_s.split(".")

      arr.inject(model_object) {|o, a| o.send(a) }
    end

    def send_chain(method_chain)
      arr = method_chain.to_s.split(".")
      begin
        arr.inject(current_review_object) {|o, a| o.send(a) }
      rescue => e
        Rails.logger.error("Failed to process method chain #{method_chain} : #{e.message}")
        return I18n.t(".enrollment_review.missing_data")
      end
    end
  end
end
