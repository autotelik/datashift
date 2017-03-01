# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   This class holds info on a single Method callable on a domain Model
#             By holding information on the Type inbound data can be manipulated
#             into the right format for the style of operator; simple assignment,
#             appending to an association collection or a method call
#
require_relative 'operator'

module DataShift

  class ModelMethod < Operator

    include DataShift::Logging

    def self.association_types_enum
      @assoc_type_enum ||= [:belongs_to, :has_one, :has_many]
      @assoc_type_enum
    end

    def self.association_type?( type )
      association_types_enum.member?( type )
    end

    # Klass is the class of the 'parent' object i.e with the associations,
    # For example Product which may have operator orders
    attr_accessor :klass

    # The real column data from the DB - via ActiveRecord::ConnectionAdapters::Column when available

    attr_reader :connection_adapter_column

    # Operator is a population type method call on klass
    #
    # Type determines the style of operator call; simple assignment, an association or a method call
    #
    def initialize(klass, operator, type, connection_adapter_column = nil)

      super(operator, type)

      @klass = klass

      # Note : Not all assignments will currently have a column type, for example
      # those that are derived from a delegate_belongs_to
      keys =  Module.const_defined?(:Mongoid) ? klass.fields.keys : klass.columns.map(&:name)
      @connection_adapter_column = keys.find { |col| col == operator } if connection_adapter_column.nil?

      @connection_adapter_column = DataShift::ModelMethods::Catalogue.column_type_for(klass, operator) if connection_adapter_column.nil?
    end

    # Return the operator's expected class name, if can be derived, else nil
    def operator_class_name
      @operator_class_name ||=
        if operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one)

          determine_operator_class.name

        elsif connection_adapter_column
          connection_adapter_column.type.to_s.classify
        else
          ''
        end

      @operator_class_name
    end

    # Return the operator's expected class, if can be derived, else nil
    def operator_class
      @operator_class ||= determine_operator_class
    end

    # Returns true of MM is an association (rather than plain attribute or, enum or method)
    def association_type?
      ModelMethod.association_type?( operator_type )
    end

    def association_columns
      klass.reflect_on_association(operator).klass.columns
    end

    def ==(other)
      other.class == self.class && other.state == state
    end

    include Comparable

    def <=>(other)
      state <=> other.state
    end

    alias eql? ==

    def hash
      state.hash
    end

    def pp
      x = <<-EOS
      Class         [#{klass.name}]
      Operator Type [#{operator_type}]
      Operator      [#{operator}]
      EOS

      if can_cast?
        x += <<-EOS
      Col/SqlType   [#{connection_adapter_column.class} - #{connection_adapter_column.cast_type.class.name}]
        EOS
      end
      x
    end

    delegate :cast_type, to: :connection_adapter_column, allow_nil: true

    def can_cast?
      connection_adapter_column && connection_adapter_column.respond_to?(:cast_type)
    end

    protected

    # Defines the precedence order.
    # For example in import, generally you want to process attributes first so that by
    # the time you get to associations you have a valid model instance with an ID
    # hence operator_type before operator
    #
    def state
      [klass.name, ModelMethod.supported_types_enum.index(operator_type), operator]
    end

    private

    # Return the operator's expected class, if can be derived, else nil
    def determine_operator_class

      if operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one)

        result = klass.reflect_on_association(operator)

        return result.klass if result

        result = MapperUtils.class_from_string(operator.classify)

        if result.nil?
          begin

            first = klass.to_s.split('::').first
            logger.debug "Trying to find operator class with Parent Namespace #{first}"

            result = MapperUtils.const_get_from_string("#{first}::#{operator.classify}")
          rescue => e
            logger.error("Failed to derive Class for #{operator} (#{@operator_type} - #{e.inspect}")
          end
        end

        result

      elsif connection_adapter_column
        begin
          Kernel.const_get(connection_adapter_column.type.to_s.classify)
        rescue
          nil
        end
      end
    end

  end
end
