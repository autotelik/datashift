# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
module DataShift

  class DataFlowNode

    include DataShift::Logging

    attr_reader :header
    attr_reader :model_method

    def initialize
      @node_collection = NodeCollection.new
    end

    def prepare_from_file(file_name, locale_key = "data_flow_schema")
      yaml = YAML.load( File.read(file_name) )

      prepare_from_yaml(yaml, locale_key)
    end

    def prepare_from_string(text, locale_key = "data_flow_schema")
      yaml = YAML.load(text)

      prepare_from_yaml(yaml, locale_key)
    end

    def prepare_from_yaml(yaml, locale_key = "data_flow_schema")

      @node_collection = NodeCollection.new

      raise RuntimeError.new("Bad YAML syntax  - No key #{locale_key} found in #{yaml}") unless yaml[locale_key]

      nodes = yaml[locale_key]['nodes']

      logger.info("Nodes: #{nodes.inspect}")

      unless(nodes.is_a?(Array))
        Rails.logger.error("Bad syntax in your review YAML - Nodes should be a sequence")
        raise RuntimeError, "Bad syntax in your review YAML - Nodes should be a sequence"
      end

      # Return a collection of Nodes

      nodes.collect do |node|
#        heading:
#         source: "title"
#         destination: "Title"
#       operator:

        logger.info("Node: #{node.inspect}")

        @current_section = node

        unless(node.is_a?(Hash) && node.size == 1)
          Rails.logger.error("Bad syntax in your review YAML - Node should be a single hash")
          raise RuntimeError, "Bad syntax in your review YAML - Node should be a single hash"
        end

        @node_collection = DataFlowNode.new(node.keys.first)

        # Possible Enhancement required :
        # As it stands this will NOT preserve the Order as defined exactly in the YAML as it's a HASH
        # with keys - for direct & association nodes - which are unordered.
        # So currently had to make arbitrary decision to process direct first, then associations

        data_section = node.values



        # Associated data - children of parent

        key = "#{locale_key}.nodes.#{current_section}.associations"

        if(I18n.exists?(key))

          association_list = I18n.t("#{locale_key}.nodes.#{current_section}.associations", default: [])

          association_list.each do |association_data|
            unless(association_data.size == 2)
              Rails.logger.error("Bad syntax in your review YAML - expect each association to have name and fields")
              next
            end

            # Each association should have a row defined as a list i.e Array
            #  -  :title: Business trading name
            #     :name: full_name
            #
            unless(association_data[1].respond_to?(:each))
              Rails.logger.error("Bad syntax in review YAML - each row needs a title, method and optional link")
              next
            end

            # The first element is the association name or chain,
            # i.e method(s) to call on the parent model to reach child with the actual data
            association_method = association_data[0].to_s

            review_object = begin
              find_association(association_method)
            rescue => e
              Rails.logger.error(e.message)
              Rails.logger.error("Bad syntax in review YAML - Could not load associated object #{association_method}")
              next
            end

            unless(review_object)
              Rails.logger.error("Nil association for #{association_method} on #{model} - no review data available")
              next
            end

            # The second element is a list of rows, made up of title, method to call on association and the state link
            association_data[1].each { |column| row_to_node_collection(review_object, column) }
          end
        end

        node_collection
      end
    end

    private

    attr_accessor :current_section, :current_review_object, :node_collection

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
