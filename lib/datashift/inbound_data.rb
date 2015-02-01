# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::  Store details of the inbound data from Excel, CSV files etc

module DataShift

  # Store data supplied to find an instance of an object (e.g find Associations)

  class LookupSupport

    attr_accessor :klass,  :field, :value

    def initialize(klass, in_name, in_value)
      @klass= klass
      @field = in_name
      @value = in_value
    end
  end

  # The raw, client supplied data such as column heading, column index etc
  # Heading may contain additional data such as lookup fields, defaults etc
  #
  class InboundColumn

    attr_accessor :file_name

    attr_accessor :name, :index

    attr_accessor :lookup_list, :data

    def initialize( in_name, in_index = -1)
      @name = in_name.to_s
      @index = in_index

      @lookup_list = []
      @data = []
    end

    def first_lookup
      @lookup_list.first || LookupSupport.new(Class, nil, nil)
    end

    def add_lookup( klass, field, value )
      @lookup_list.unshift( LookupSupport.new(klass, field, value) )
    end

    def find_by_operator
      first_lookup.field
    end

    def find_by_value
      first_lookup.value
    end

  end
  
end