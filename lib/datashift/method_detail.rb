# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   This class provides info and access to the details of individual population methods
#             on an AR model. Populated by, and coupled with MethodMapper,
#             which does the model interrogation work and stores sets of MethodDetails.
#
#             Enables 'loaders' to iterate over the MethodMapper results set,
#             and assign values to AR object, without knowing anything about that receiving object.
#
require 'set'

module DataShift

  class MethodDetail

    include DataShift::Logging
      
    def self.supported_types_enum
      @type_enum ||= Set[:assignment, :belongs_to, :has_one, :has_many]
      @type_enum
    end

    def self.association_types_enum
      @assoc_type_enum ||= Set[:belongs_to, :has_one, :has_many]
      @assoc_type_enum
    end


    def self.is_association_type? ( type )
      association_types_enum.member?( type )
    end


    # Klass is the class of the 'parent' object i.e with the associations,
    # For example Product which may have operator orders
    attr_accessor :klass
    
    # Name is the raw, client supplied name e.g Orders
    attr_accessor :name
    attr_accessor :column_index
  
    # The rel col type from the DB
    attr_reader :col_type, :current_value

    # The :operator that can be called to assign  e.g orders or Products.new.orders << Order.new
    # 
    # The type of operator e.g :assignment, :belongs_to, :has_one, :has_many etc
    attr_reader :operator, :operator_type

    # TODO make it a list/primary keys
    attr_accessor :find_by_operator, :find_by_value
        
    # Store the raw (client supplied) name against the active record  klass(model).
    # Operator is the associated method call on klass,
    # i.e client supplies name 'Price' in a spreadsheet, 
    # but true operator to call on klass is price
    # 
    # col_types can typically be derived from klass.columns - set of ActiveRecord::ConnectionAdapters::Column

    def initialize(client_name, klass, operator, type, col_types = {}, find_by_operator = nil, find_by_value = nil )
      @klass, @name = klass, client_name
      @find_by_operator = find_by_operator || operator
      @find_by_value = find_by_value

      if( MethodDetail::supported_types_enum.member?(type.to_sym) )
        @operator_type = type.to_sym
      else
        raise "Bad operator Type #{type} passed to Method Detail"
      end

      @operator = operator
    
      # Note : Not all assignments will currently have a column type, for example
      # those that are derived from a delegate_belongs_to
      if(col_types.empty?)
        @col_type = klass.columns.find{ |col| col.name == operator }
      else
        @col_type = col_types[operator]
      end
      
      @column_index = -1
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
    def operator_class_name()
      @operator_class_name ||= 
        if(operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one))
   
        get_operator_class.name
  
      elsif(@col_type)
        @col_type.type.to_s.classify
      else
        ""
      end

      @operator_class_name
    end

    # Return the operator's expected class, if can be derived, else nil
    def operator_class()
      @operator_class ||= get_operator_class()
      @operator_class
    end

    def pp
      "#{@name} => #{operator}"
    end

    private

    # Attempt to find the associated object via id, name, title ....
    def insistent_belongs_to( record, value )

      if( value.class == operator_class)
        record.send(operator) << value
      else

        @@insistent_find_by_list.each do |x|
          begin
            next unless operator_class.respond_to?( "find_by_#{x}" )
            item = operator_class.send( "find_by_#{x}", value)
            if(item)
              record.send(operator + '=', item)
              break
            end
          rescue => e
            logger.error "Failed to match belongs_to association #{value}"
            puts "ERROR: #{e.inspect}"
            if(x == Populator::insistent_method_list.last)
              raise "I'm sorry I have failed to assign [#{value}] to #{@assignment}" unless value.nil?
            end
          end
        end
      end
    end

    # Attempt to find the associated object via id, name, title ....
    def insistent_has_many( record, value )

      if( value.class == operator_class)
        record.send(operator) << value
      else
        @@insistent_find_by_list.each do |x|
          begin
            item = operator_class.send( "find_by_#{x}", value)
            if(item)
              record.send(operator) << item
              break
            end
          rescue => e
            puts "ERROR: #{e.inspect}"
            if(x == Populator::insistent_method_list.last)
              raise "I'm sorry I have failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end
    
    private
  
    # Return the operator's expected class, if can be derived, else nil
    # TODO this should call operator_class_name once we work out how to handle namespaced classes
    # in that method
    def get_operator_class()
      
      if(operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one))
   
        result = ModelMapper::class_from_string(operator.classify)
        
        if(result.nil?)
          begin
            
            first = klass.to_s.split('::').first
            logger.debug "Trying to find operator class with Parent Namespace #{first}"

            result = ModelMapper::const_get_from_string("#{first}::#{operator.classify}")
          rescue => e
            logger.error(e.inspect)
            logger.error("Could not derive Class Name for #{@operator_type} (#{@operator_type})")
          end
        end
        
        result

      elsif(@col_type)
        begin
          Kernel.const_get(@col_type.type.to_s.classify)
        rescue; nil; end
      else
        nil
      end
    end
    
  end
  
end