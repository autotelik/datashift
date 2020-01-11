# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Holds the current headers and any pre-processing
#             mapping done on them
#
#             There are a number of configuration options available to
#             process the collection of Columns to be worked on - see DataShift::Configuration
#
#
require 'forwardable'

module DataShift

  # Acts as an array

  class Headers

    attr_accessor :source

    # Row Index
    attr_reader :idx

    extend Forwardable

    def_delegators :@headers, *Array.delegated_methods_for_fwdable

    def initialize(source, header_row_index = 0, headers = [])
      @source = source
      @idx = header_row_index
      @headers = headers
    end

    # Check for either string or symbol version of a header
    def header?( header)
      h = header.is_a?(ModelMethod) ? header.operator : header
      (sources & [h, h.to_sym]).present?
    end

    def index(header)
      h = header.is_a?(ModelMethod) ? header.operator : header
      sources.index(h) || sources.index(h.to_sym)
    end


    # Factory for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    # See config options
    #
    #   :remove_columns - List of columns to remove from files
    #
    #   :remove_rails - Remove standard Rails cols like :id, created_at etc
    #
    class << self

      def klass_to_operators(klass, config: DataShift::Configuration.call)

        headers = Headers.new(klass, config: config)

        headers.class_source_to_headers

        DataShift::Transformation::RemoveUnwantedHeaders.call(headers, config: config)

        headers
      end

      alias klass_to_headers klass_to_operators
    end

    # Helpers for dealing with source = class, usually an Active Record model
    # Catalogs the supplied Klass and builds set of expected/valid method calls (operators) for Klass
    # from sll the available method calls on class
    # These can be used to infer an operator to call from an inbound header
    # or provide mapping to an internal method from an external header
    #
    def class_source_to_operators(config: DataShift::Configuration.call)

      raise SourceIsNotAClass, 'Cannot parse source for headers - source must be a Class' unless source.is_a?(Class)

      # TODO: This collection can now be sorted
      collection = ModelMethods::Manager.catalog_class(source)

      if collection
        collection.each do |mm|
          next if(DataShift::Transformation::Remove.new.association?(mm))

          next unless config.op_type_in_scope?(mm)
          if(mm.association_type?)
            association_to_headers(mm)
          else
            # TODO - can/shoudl we standardise to always store symbols - this is currently String
            add mm.operator
          end
        end
      end
    end

    alias class_source_to_headers class_source_to_operators

    def association_to_headers( model_method, config: DataShift::Configuration.call)

      if(config.expand_associations)
        model_method.association_columns.each do |c|
          add "#{model_method.operator}::#{c.name}"
        end
      else
        add model_method.operator
      end
    end

    def add(source, presentation: nil)
      @headers << Header.new(source: source, presentation: presentation)
    end

    def sources
      @headers.collect(&:source)
    end

    def row_index
      idx
    end

  end
end
