# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::  Store details of the inbound data from Excel, CSV files etc

module DataShift

  module InboundData

    # The raw, client supplied data such as column heading, column index etc
    # Heading may contain additional data such as lookup fields, defaults etc
    #
    class Column

      attr_accessor :file_name

      attr_accessor :name, :index

      attr_accessor :lookup_list, :data

      def initialize( in_name, in_index = -1)
        @name = in_name.to_s
        @index = in_index

        @lookup_list = []
        @data = []
      end

      alias_method :lookups, :lookup_list

      def add_lookup( klass, field, where_value )
        @lookup_list.unshift( LookupSupport.new(klass, field, where_value) )
      end

      def find_by_operator
        lookup_list.first ? lookup_list.first.field : ""
      end

      def find_by_value
        lookup_list.first ? lookup_list.first.value : ""
      end

    end
  end
end