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

    delegate :source, to: :inbound_column, allow_nil: true
    delegate :index, to: :inbound_column, allow_nil: true

    # Is this method detail a valid mapping, aids identifying unmapped/unmappable columns
    attr_accessor :valid

    # Store the raw (client supplied) name against the active record  klass(model).
    # Operator is the associated method call on klass,
    # i.e client supplies name 'Price' in a spreadsheet,
    # but true operator to call on klass is price
    #
    # type determines the style of operator call; simple assignment, an association or a method call
    #
    # col_types can typically be derived from klass.columns - set of ActiveRecord::ConnectionAdapters::Column

    def initialize(name, idx, model_method)
      @inbound_column = InboundData::Column.new(name, idx)

      @model_method = model_method

      @valid = name && model_method ? true : false
    end

    # TODO: - use delegators
    def operator
      model_method ? model_method.operator : ''
    end

    def operator?(name, case_sensitive = false)
      model_method ? model_method.operator?(name, case_sensitive) : false
    end

    def klass
      model_method.klass
    end

    def class_name
      model_method.klass.name
    end

    def add_column_data(data)
      inbound_column.data << data if(inbound_column)
    end

    # Example :
    # Project:name:My Best Project
    #   User (klass) has_one project  lookup where name(field) == 'My Best Project' (value)
    #   User.project.where( :name => 'My Best Project')

    def add_lookup( model_method, field, value)

      # check the finder method name is a valid field on the actual association class
      klass = model_method.klass

      association = klass.reflect_on_association(model_method.operator)

      # TODO: - this is instance methods .. what about class methods ?
      if association && association.klass.new.respond_to?(field)
        inbound_column.add_lookup(association.klass, field, value)
        logger.info("Complex Lookup specified for [#{model_method.operator}] : on field [#{field}] (optional value [#{value}])")
      else
        logger.error("Check MethodBinding [#{source}](#{index}) - Association field names are case sensitive")
        raise NoSuchOperator, "Field [#{field}] Not Found on Association [#{model_method.operator}] within Class #{klass.name}"
      end
    end

    def valid?
      (@valid == true)
    end

    def invalid?
      !valid?
    end

    def pp
      "Binding: Column [#{index}] : Header [#{source}] : Operator [#{model_method.operator}]"
    end

    def spp
      "Column [#{index}] : Header [#{source}]"
    end

  end

  class InternalMethodBinding < MethodBinding

    # Store an internal custom Operator to be called on klass
    # Enables data to be set on a klass when no header/inbound data present
    # For example to set default data, or for custom processing of inbound data

    def initialize(model_method)
      @model_method = model_method
      @valid = true
    end

    def index
      nil
    end

    def source
      :internal
    end

  end

  class NoMethodBinding < MethodBinding

    attr_accessor :reason

    def initialize(client_name = '', client_idx = -1, options = {})
      super(client_name, client_idx, nil)

      @reason = options[:reason] || ''
    end

    def invalid?
      !valid?
    end

    def valid?
      false
    end

    def pp
      "No Binding Found : Row [#{index}] : Header [#{source}]"
    end

  end

end
