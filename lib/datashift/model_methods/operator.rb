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
module DataShift

  class Operator

    include DataShift::Logging

    # List of supported operator types e.g :assignment, :belongs_to, :has_one, :has_many etc
    # N.B these are in priority order ie. often prefer to process assignments first, then associations
    #
    def self.supported_types_enum
      @type_enum ||= [:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
      @type_enum
    end

    # The :operator that can be called to assign  e.g orders or Products.new.orders << Order.new
    attr_reader :operator

    # The type of operator e.g normal method or Rails :assignment, :belongs_to, :has_one, :has_many etc
    attr_reader :operator_type

    # Operator is a population type method call
    # Type determines the style of operator call; simple assignment, an association or a method call
    #
    def initialize(operator, type = :method)

      type_as_sym = type.to_sym

      if ModelMethod.supported_types_enum.include?(type_as_sym)
        @operator_type = type_as_sym
      else
        raise BadOperatorType, "No such operator Type [#{type_as_sym}] cannot instantiate ModelMethod for #{operator}"
      end

      @operator = operator.to_s.strip
    end

    # Return the actual operator's name for supplied method type
    # where type one of :assignment, :has_one, :belongs_to, :has_many etc
    def operator_for( type )
      return operator if @operator_type == type.to_sym
      nil
    end

    def operator?(name, case_sensitive = false)
      return false if(name.nil?)
      case_sensitive ? operator == name : operator.casecmp(name.downcase).zero?
    end

    def operator_type?(type)
      @operator_type == type.to_sym
    end

  end
end
