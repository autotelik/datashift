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
require 'set'

module DataShift

  class ModelMethod

    include DataShift::Logging

    # List of supported operator types e.g :assignment, :belongs_to, :has_one, :has_many etc

    def self.supported_types_enum
      @type_enum ||= Set[:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
      @type_enum
    end

    def self.association_types_enum
      @assoc_type_enum ||= Set[:belongs_to, :has_one, :has_many]
      @assoc_type_enum
    end

    def self.is_association_type?( type )
      association_types_enum.member?( type )
    end

    # Klass is the class of the 'parent' object i.e with the associations,
    # For example Product which may have operator orders
    attr_accessor :klass

    # The rel col type from the DB
    attr_reader :col_type

    # The :operator that can be called to assign  e.g orders or Products.new.orders << Order.new
    #
    # The type of operator e.g :assignment, :belongs_to, :has_one, :has_many etc
    attr_reader :operator, :operator_type

    # Operator is a population type method call on klass
    # Type determines the style of operator call; simple assignment, an association or a method call
    #
    # col_types can typically be derived from klass.columns - set of ActiveRecord::ConnectionAdapters::Column

    def initialize(klass, operator, type, col_type = nil)
      @klass = klass

      if( ModelMethod.supported_types_enum.member?(type.to_sym) )
        @operator_type = type.to_sym
      else
        fail BadOperatorType.new("No such operator Type [#{type}] cannot instantiate ModelMethod for #{operator}")
      end

      @operator = operator

      # Note : Not all assignments will currently have a column type, for example
      # those that are derived from a delegate_belongs_to
      @col_type = klass.columns.find { |col| col.name == operator } if(col_type.nil?)

      @col_type = DataShift::ModelMethods::Catalogue.column_type_for(klass, operator) if(col_type.nil?)
    end

    # Return the actual operator's name for supplied method type
    # where type one of :assignment, :has_one, :belongs_to, :has_many etc
    def operator_for( type )
      return operator if(@operator_type == type.to_sym)
      nil
    end

    def operator?(name, case_sensitive = false)
      case_sensitive ? operator == name : operator.downcase == name.downcase
    end

    # Return the operator's expected class name, if can be derived, else nil
    def operator_class_name
      @operator_class_name ||=
        if(operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one))

          get_operator_class.name

        elsif(@col_type)
          @col_type.type.to_s.classify
        else
          ''
        end

      @operator_class_name
    end

    # Return the operator's expected class, if can be derived, else nil
    def operator_class
      @operator_class ||= get_operator_class
      @operator_class
    end

    def pp
      x = <<-EOS
      Class         [#{klass.name}]
      Operator Type [#{operator_type}]
      Operator      [#{operator}]
      EOS

      if(col_type.respond_to?(:cast_type))
        x +=<<-EOS
      Col/SqlType   [#{col_type.class} - #{col_type.cast_type.class.name}]
        EOS
      end
      x
    end

    private

    # Return the operator's expected class, if can be derived, else nil
    def get_operator_class

      if(operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one))

        result = klass.reflect_on_association(operator)

        return result.klass if(result)

        result = MapperUtils.class_from_string(operator.classify)

        if(result.nil?)
          begin

            first = klass.to_s.split('::').first
            logger.debug "Trying to find operator class with Parent Namespace #{first}"

            result = MapperUtils.const_get_from_string("#{first}::#{operator.classify}")
          rescue => e
            logger.error("Failed to derive Class for #{operator} (#{@operator_type} - #{e.inspect}")
          end
        end

        result

      elsif(@col_type)
        begin
          Kernel.const_get(@col_type.type.to_s.classify)
        rescue;
          nil;
        end
      end
    end
  end
end
