# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Holds the current headers amd any pre-processing
#             mapping done on them
#
require 'forwardable'

module DataShift

  class Headers

    extend Forwardable # For def_delegators

    attr_accessor :source, :configuration

    attr_reader :previous_headers

    attr_reader :idx

    def_delegators :@headers, *Array.instance_methods.delete_if { |i| i.match(/__.*|class|object_id/) }

    def initialize(source, idx = 0, headers = [])
      @source = source
      @idx = idx
      @headers = headers
      @previous_headers = []
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
            @headers << mm.operator
          end if(configuration.op_type_in_scope?(mm))
        end

        DataShift::Transformer::Remove.unwanted_columns(@headers)
      end
    end

    def association_to_headers( model_method )
      if(configuration.expand_associations)
        model_method.association_columns.each do |c|
          heading = "#{model_method.operator}::#{c.name}"
          @headers << heading
        end
      else
        @headers << model_method.operator
      end
    end

    # Swap any raw inbound column headers for their mapped equivalent
    # mapping = {'Customer' => 'user'}
    #
    # In Excel/csv header is 'Customer',
    # this is now swapped for 'user' which is correct domain operator.
    #
    def swap_inbound( mapping )
      @previous_headers = @headers.dup
      mapping.each do |m, v|
        @headers.index_at(m)
        @headers[i] = v
      end
      @mapped = true
    end

    def mapped?
      @mapped
    end

    def row_index
      idx
    end

  end
end
