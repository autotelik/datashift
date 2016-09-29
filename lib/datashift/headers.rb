# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Holds the current headers and any pre-processing
#             mapping done on them
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

    def initialize(source, idx = 0, headers = [])
      @source = source
      @idx = idx
      @headers = headers
    end

    # Factory for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def self.klass_to_headers(klass)

      headers = Headers.new(klass)

      headers.class_source_to_headers

      DataShift::Transformation::Remove.new.unwanted_headers(headers)

      headers
    end

    # Helpers for dealing with source = class, usually an Active Record model
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def class_source_to_headers

      raise SourceIsNotAClass, 'Cannot parse source for headers - source must be a Class' unless source.is_a?(Class)

      # TODO: This collection can now be sorted
      collection = ModelMethods::Manager.catalog_class(source)

      configuration = DataShift::Configuration.call

      collection.each do |mm|
        next if(DataShift::Transformation::Remove.new.association?(mm))

        if(mm.association_type?)
          association_to_headers(mm)
        else
          add mm.operator
        end if(configuration.op_type_in_scope?(mm))
      end if collection
    end

    def association_to_headers( model_method )

      configuration = DataShift::Configuration.call

      if(configuration.expand_associations)
        model_method.association_columns.each do |c|
          add "#{model_method.operator}::#{c.name}"
        end
      else
        add model_method.operator
      end
    end

    def add(source)
      @headers << Header.new(source: source)
    end

    def sources
      @headers.collect(&:source)
    end

    def row_index
      idx
    end

  end
end
