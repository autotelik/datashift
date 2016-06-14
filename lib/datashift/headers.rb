# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Holds the current headers and any pre-processing
#             mapping done on them
#
require 'forwardable'

module DataShift

  class Headers

    extend Forwardable # For def_delegators

    attr_accessor :source, :configuration

    attr_reader :idx

    def_delegators :@headers, *Array.instance_methods.delete_if { |i| i.match(/__.*|class|object_id/) }

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

      if collection
        collection.each do |mm|
          next if(DataShift::Transformer::Remove.association?(mm))

          if(mm.association_type?)
            association_to_headers(mm)
          else
            add mm.operator
          end if(configuration.op_type_in_scope?(mm))
        end

        DataShift::Transformer::Remove.unwanted_columns(@headers)
      end
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
      @headers << Header.new(source: source)
    end
    def mapped?
      @mapped
    end

    def row_index
      idx
    end

  end
end
