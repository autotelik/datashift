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

    attr_accessor :source, :configuration

    # Row Index
    attr_reader :idx

    extend Forwardable

    def_delegators :@headers, *Array.delegated_methods_for_fwdable

    def initialize(source, idx = 0, headers = [])
      @source = source
      @idx = idx
      @headers = headers

      @mapped = false

      @configuration = DataShift::Configuration.call
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def source_to_headers

      # TODO: This collection can now be sorted
      collection = ModelMethods::Manager.catalog_class(source)

      collection.each do |mm|
        next if(DataShift::Transformer::Remove.association?(mm))

        if(mm.association_type?)
          association_to_headers(mm)
        else
          add mm.operator
        end if(configuration.op_type_in_scope?(mm))
      end if collection
    end

    def association_to_headers( model_method )
      if(configuration.expand_associations)
        model_method.association_columns.each do |c|
          add "#{model_method.operator}::#{c.name}"
        end
      else
        add model_method.operator
      end
    end

    def add(source)
      @headers << Header.new(source: source, destination: source)
    end

    def destinations
      @headers.collect(&:destination)
    end

    def row_index
      idx
    end

  end
end
