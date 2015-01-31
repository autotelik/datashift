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

    attr_reader :inbound_column

    # Is this method detail a valid mapping, aids identifying unmapped/unmappable columns
    attr_accessor :valid

    def operator
      model_method.operator
    end

    def inbound_name
      inbound_column.name
    end

    def inbound_index
      inbound_column.index
    end

    def add_column_data(data)
      inbound_column.data = data
    end

    # Example :
    # Project:name:My Best Project
    #   User (klass) has_one project  lookup where name(field) == 'My Best Project' (value)
    #   User.project.where( :name => 'My Best Project')

    def add_lookup( model_method, field, value)

      # check the finder method name is a valid field on the actual association class
      klass = model_method.mapped_class

      association = klass.reflect_on_association(model_method.operator)

      # TODO - this is instance methods .. what about class methods ?
      if(association && association.klass.new.respond_to?(where_field))
        model_method.add_lookup(association.klass, field, value)
        logger.info("Complex Lookup specified for [#{model_method.operator}] : on field [#{field}] (optional value [#{value}])")
      else
        logger.warn("Find by operator [#{field}] Not Found on Association [#{model_method.operator}] with Class #{klass.name}")
        logger.warn("Check column (#{model_method.inbound_data.index}) heading - e.g association field names are case sensitive")
        # TODO - maybe derived loaders etc want this data for another purpose - should we stash elsewhere ?
      end
    end

    # Store the raw (client supplied) name against the active record  klass(model).
    # Operator is the associated method call on klass,
    # i.e client supplies name 'Price' in a spreadsheet, 
    # but true operator to call on klass is price
    #
    # type determines the style of operator call; simple assignment, an association or a method call
    # 
    # col_types can typically be derived from klass.columns - set of ActiveRecord::ConnectionAdapters::Column

    def initialize(name, idx, model_method)
      @inbound_column = InboundColumn.new(name, idx)

      @model_method = model_method

      @valid = (name.nil? || model_method.nil?) ? false : true
    end

    def valid?
      (@valid == true)
    end

    def pp
      "#{inbound_name} => #{model_method.operator}"
    end

  end

  class NoMethodBinding < MethodBinding
    def initialize(client_name, client_idx)
      super(client_name, client_idx, nil)
    end

    def valid?
      false
    end
  end

end