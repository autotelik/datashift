# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::  Store details of the inbound data from Excel, CSV files etc

module DataShift

  # Store data supplied to find an instance of an object (e.g find Associations)

  class LookupSupport

    attr_accessor :field, :value

    def initialize( in_name, in_value)
      @field = in_name
      @field = in_value
    end
  end

  # The raw, client supplied data such as column heading, column index etc
  class InboundColumn

    attr_accessor :file_name

    attr_accessor :name
    attr_accessor :index

    def initialize( in_name, in_index = -1)
      @name = in_name
      @index = in_index

      @header_lookup_list = []    # set in header so apply to all rows

      @lookup_list = []
    end

    # Additional helpers for where clauses
    attr_accessor :lookup_support_list

    # TODO remove now in lookup_support_list
    #attr_accessor :find_by_operator, :find_by_value

    def header_lookup
      @header_lookup_list.first || LookupSupport.new(nil, nil)
    end

    def add_header_lookup( field, value )
      @header_lookup_list.unshift( LookupSupport.new(field, value) )
    end

    def find_by_operator
      lookup_support_list.first.field
    end

    def find_by_value
      lookup_support_list.first.value
    end

    def add_lookup_field( field, value )
      @lookup_list.unshift( LookupSupport.new(field, value) )
    end


  end
  
end