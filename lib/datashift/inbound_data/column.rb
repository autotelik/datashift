# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
# Details::   The basic raw Header info from a client - column heading, column indexx
#             Column contains additional data such as lookup fields, defaults etc
#

module DataShift

  module InboundData

    class Column

      attr_accessor :header, :index, :lookup_list, :data

      def initialize(source, index = -1)

        @header = DataShift::Header.new(source: source)

        @index = index
        @lookup_list = []
        @data = []
      end

      delegate :source, to: :header

      alias lookups lookup_list

      def add_lookup( klass, field, where_value )
        @lookup_list.unshift( LookupSupport.new(klass, field, where_value) )
      end

      def find_by_operator
        lookup_list.first ? lookup_list.first.field : ''
      end

      def find_by_value
        lookup_list.first ? lookup_list.first.value : ''
      end

    end
  end
end
