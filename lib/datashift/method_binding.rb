# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Bind incoming data to it's associated domain model
#             Link headers to the details of individual population methods
#
#             Enables 'loaders' to iterate over the incoming data set, and assign
#             values to domain object, without knowing anything about that receiving object.
#
require 'set'

module DataShift

  class MethodBinding

    include DataShift::Logging

    attr_reader :model_method

    attr_reader :inbound_data

    # Is this method detail a valid mapping, aids identifying unmapped/unmappable columns
    attr_accessor :valid

    def inbound_name
      inbound_data.name
    end

    def inbound_index
      inbound_data.index
    end

    def set_inbound_data( raw_name, index)
      inbound_data.name = raw_name
      inbound_data.index = index
    end

    # Store the raw (client supplied) name against the active record  klass(model).
    # Operator is the associated method call on klass,
    # i.e client supplies name 'Price' in a spreadsheet, 
    # but true operator to call on klass is price
    #
    # type determines the style of operator call; simple assignment, an association or a method call
    # 
    # col_types can typically be derived from klass.columns - set of ActiveRecord::ConnectionAdapters::Column

    def initialize(client_name, model_method)
      @inbound_data = InboundColumn.new(client_name)

      @model_method = model_method

      @valid = TODO
    end

    def valid?
      @valid == true
    end

    def pp
      "#{@name} => #{model_method.operator}"
    end

  end
end