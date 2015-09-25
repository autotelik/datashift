# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::  Store details of the inbound data from Excel,CSV files etc

module DataShift

  module InboundData

    # Store data supplied from client to find an instance of an object (e.g find Associations)

    # Klass.where( @field => @where_value)

    class LookupSupport

      attr_reader :klass, :field, :where_value

      def initialize(klass, in_name, where_value)
        @klass = klass
        @field = in_name
        @where_value = where_value
      end

      def find
        klass.where( field => where_value )
      end

    end

  end
end
