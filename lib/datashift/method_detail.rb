# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   This class provides info and access to the individual population methods
#             on an AR model. Populated by, and coupled with MethodMapper,
#             which does the model interrogation work and stores sets of MethodDetails.
#
#             Enables 'loaders' to iterate over the MethodMapper results set,
#             and assign values to AR object, without knowing anything about that receiving object.
#
require 'to_b'

module DataShift

  class MethodDetail

    def self.type_enum
      @type_enum ||= Set[:assignment, :belongs_to, :has_one, :has_many]
      @type_enum
    end

    # When looking up an association, try each of these in turn till a match
    #  i.e find_by_name .. find_by_title and so on, lastly try the raw id
    @@insistent_find_by_list ||= [:name, :title, :id]

    # Name is the raw, client supplied name
    attr_reader :name, :col_type, :current_value

    attr_reader :operator, :operator_type

    # Store the raw (client supplied) name against the active record  klass(model), operator and types
    # col_types can typically be derived from klass.columns - set of ActiveRecord::ConnectionAdapters::Column

    def initialize(client_name, klass, operator, type, col_types = {} )
      @klass, @name = klass, client_name

      if( MethodDetail::type_enum.member?(type.to_sym) )
        @operator_type = type
      else
        raise "Bad operator Type #{type} passed to Method Detail"
      end

      @operator = operator
    
      # Note : Not all assignments will currently have a column type, for example
      # those that are derived from a delegate_belongs_to
      @col_type = col_types[operator]
    end


    # Return the actual operator's name for supplied method type
    # where type one of :assignment, :has_one, :belongs_to, :has_many etc
    def operator_for( type )
      return operator if(@operator_type == type)
      nil
    end

    def operator?(name)
      operator == name
    end

    # Return the operator's expected class name, if can be derived, else nil
    def operator_class_name()
      @operator_class_name ||= if(operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one))
        begin
          Kernel.const_get(operator.classify)
          operator.classify
        rescue; ""; end
  
      elsif(@col_type)
        @col_type.type.to_s.classify
      else
        ""
      end

      @operator_class_name
    end

    # Return the operator's expected class, if can be derived, else nil
    def operator_class()
      @operator_class ||= if(operator_for(:has_many) || operator_for(:belongs_to) || operator_for(:has_one))
        begin
          Kernel.const_get(operator.classify)
        rescue; ""; end

      elsif(@col_type)
        begin
          Kernel.const_get(@col_type.type.to_s.classify)
        rescue; nil; end
      else
        nil
      end

      @operator_class
    end


    def assign(record, value )
      
      @current_value = value

      puts "WARNING nil value supplied for Column [#{@name}]" if(@current_value.nil?)
    
      if( operator_for(:belongs_to) )
      
        #puts "DEBUG : BELONGS_TO : #{@name} : #{operator} - Lookup #{@current_value} in DB"
        insistent_belongs_to(record, @current_value)

      elsif( operator_for(:has_many) )

        #puts "DEBUG : HAS_MANY :  #{@name} : #{operator}(#{operator_class}) - Lookup #{@current_value} in DB"
        if(value.is_a?(Array) || value.is_a?(operator_class))
          record.send(operator) << value
        else
          puts "ERROR #{value.class} - Not expected type for has_many #{operator} - cannot assign"
          # TODO -  Not expected type - maybe try to look it up somehow ?"
          #insistent_has_many(record, @current_value)
        end

      elsif( operator_for(:has_one) )

        #puts "DEBUG : HAS_MANY :  #{@name} : #{operator}(#{operator_class}) - Lookup #{@current_value} in DB"
        if(value.is_a?(operator_class))
          record.send(operator + '=', value)
        else
          puts "ERROR #{value.class} - Not expected type for has_one #{operator} - cannot assign"
          # TODO -  Not expected type - maybe try to look it up somehow ?"
          #insistent_has_many(record, @current_value)
        end

      elsif( operator_for(:assignment) && @col_type )
        #puts "DEBUG : COl TYPE defined for #{@name} : #{@assignment} => #{@current_value} #{@col_type.type}"
        #puts "DEBUG : COl TYPE CAST: #{@current_value} => #{@col_type.type_cast( @current_value ).inspect}"
        record.send( operator + '=' , @col_type.type_cast( @current_value ) )

        #puts "DEBUG : MethodDetails Assignment RESULT: #{record.send(operator)}"

      elsif( operator_for(:assignment) )
        #puts "DEBUG : Brute force assignment of value  #{@current_value} supplied for Column [#{@name}]"
        # brute force case for assignments without a column type (which enables us to do correct type_cast)
        # so in this case, attempt straightforward assignment then if that fails, basic ops such as to_s, to_i, to_f etc
        insistent_assignment(record, @current_value)
      else
        puts "WARNING: No operator found for assignment on #{self.inspect} for Column [#{@name}]"
      end
    end

    def pp
      "#{@name} => #{operator}"
    end


    def self.insistent_method_list
      @insistent_method_list ||= [:to_s, :to_i, :to_f, :to_b]
      @insistent_method_list
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
            puts "ERROR: #{e.inspect}"
            if(x == MethodDetail::insistent_method_list.last)
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
            if(x == MethodDetail::insistent_method_list.last)
              raise "I'm sorry I have failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end

    def insistent_assignment( record, value )
      #puts "DEBUG: RECORD CLASS #{record.class}"
      op = operator + '='
    
      begin
        record.send(op, value)
      rescue => e
        MethodDetail::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
            #puts "DEBUG: insistent_assignment: #{e.inspect}"
            if f == MethodDetail::insistent_method_list.last
              puts  "I'm sorry I have failed to assign [#{value}] to #{operator}"
              raise "I'm sorry I have failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end
  end
  
end