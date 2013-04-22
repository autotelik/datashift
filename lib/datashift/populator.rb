# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     March 2012
# License::   MIT
#
# Details::   The default Populator class for assigning data to models
#             
#             Provides individual population methods on an AR model.
#
#             Enables users to assign values to AR object, without knowing much about that receiving object.
#
require 'to_b'
require 'logging'

module DataShift

  class Populator
    
    include DataShift::Logging
        
    def self.insistent_method_list
      @insistent_method_list ||= [:to_s, :to_i, :to_f, :to_b]
    end
 
    # When looking up an association, when no field provided, try each of these in turn till a match
    # i.e find_by_name, find_by_title, find_by_id
    def self.insistent_find_by_list
      @insistent_find_by_list ||= [:name, :title, :id]
    end
    
    
    attr_reader :current_value, :original_value_before_override
    attr_reader :current_attribute_hash
    attr_reader :current_method_detail
    
    def initialize   
      @current_value = nil
      @original_value_before_override = nil
      @current_attribute_hash = {}

    end
    
    # Set member variables to hold details, value and optional attributes.
    # 
    # Check supplied value, validate it, and if required :
    #   set to provided default value
    #   prepend any provided prefixes 
    #   add any provided postfixes
    def prepare_data(method_detail, value)
      
      @current_value, @current_attribute_hash = value.to_s.split(Delimiters::attribute_list_start)
      
      if(@current_attribute_hash)
        @current_attribute_hash.strip!
        puts "DEBUG: Populator Value contains additional attributes"
        @current_attribute_hash = nil unless @current_attribute_hash.include?('}')
      end
      
      @current_attribute_hash ||= {}
      
      @current_method_detail = method_detail
      
      operator = method_detail.operator
      
      override_value(operator)
        
      if((value.nil? || value.to_s.empty?) && default_value(operator))
        @current_value = default_value(operator)
      end
      
      @current_value = "#{prefix(operator)}#{@current_value}" if(prefix(operator))
      @current_value = "#{@current_value}#{postfix(operator)}" if(postfix(operator))

      return @current_value, @current_attribute_hash
    end
    
    def assign(method_detail, record, value )
      
      @current_value = value

      # logger.info("WARNING nil value supplied for Column [#{@name}]") if(@current_value.nil?)

      operator = method_detail.operator
         
      if( method_detail.operator_for(:belongs_to) )
      
        #puts "DEBUG : BELONGS_TO : #{@name} : #{operator} - Lookup #{@current_value} in DB"
        insistent_belongs_to(method_detail, record, @current_value)

      elsif( method_detail.operator_for(:has_many) )
        
        #puts "DEBUG : VALUE TYPE [#{value.class.name.include?(operator.classify)}] [#{ModelMapper.class_from_string(value.class.name)}]" unless(value.is_a?(Array))
     
        # The include? check is best I can come up with right now .. to handle module/namespaces
        # TODO - can we determine the real class type of an association
        # e.g given a association taxons, which operator.classify gives us Taxon, but actually it's Spree::Taxon
        # so how do we get from 'taxons' to Spree::Taxons ? .. check if further info in reflect_on_all_associations

        if(value.is_a?(Array) || value.class.name.include?(operator.classify))
          record.send(operator) << value
        else
          puts "ERROR #{value.class} - Not expected type for has_many #{operator} - cannot assign"
        end

      elsif( method_detail.operator_for(:has_one) )

        #puts "DEBUG : HAS_MANY :  #{@name} : #{operator}(#{operator_class}) - Lookup #{@current_value} in DB"
        if(value.is_a?(method_detail.operator_class))
          record.send(operator + '=', value)
        else
          logger.error("ERROR #{value.class} - Not expected type for has_one #{operator} - cannot assign")
          # TODO -  Not expected type - maybe try to look it up somehow ?"
          #insistent_has_many(record, @current_value)
        end

      elsif( method_detail.operator_for(:assignment) && method_detail.col_type )
        #puts "DEBUG : COl TYPE defined for #{@name} : #{@assignment} => #{@current_value} #{@col_type.type}"
        # puts "DEBUG : Column [#{@name}] : COl TYPE CAST: #{@current_value} => #{@col_type.type_cast( @current_value ).inspect}"
        record.send( operator + '=' , method_detail.col_type.type_cast( @current_value ) )

        #puts "DEBUG : MethodDetails Assignment RESULT: #{record.send(operator)}"

      elsif( method_detail.operator_for(:assignment) )
        #puts "DEBUG : Column [#{@name}] : Brute force assignment of value  #{@current_value}"
        # brute force case for assignments without a column type (which enables us to do correct type_cast)
        # so in this case, attempt straightforward assignment then if that fails, basic ops such as to_s, to_i, to_f etc
        insistent_assignment(record, @current_value, operator)
      else
        puts "WARNING: No assignment possible on #{record.inspect} using [#{operator}]"
      end
    end
    
    def insistent_assignment(record, value, operator)
      
      #puts "DEBUG: RECORD CLASS #{record.class}"
      op = operator + '=' unless(operator.include?('='))
    
      begin
        record.send(op, value)
      rescue => e
        Populator::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
            puts "DEBUG: insistent_assignment: #{e.inspect}"
            if f == Populator::insistent_method_list.last
              puts  "I'm sorry I have failed to assign [#{value}] to #{operator}"
              raise "I'm sorry I have failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end
    
    # Attempt to find the associated object via id, name, title ....
    def insistent_belongs_to(method_detail, record, value )

      operator = method_detail.operator
      
      if( value.class == method_detail.operator_class)
        record.send(operator) << value
      else

        insistent_find_by_list.each do |x|
          begin
            next unless method_detail.operator_class.respond_to?( "find_by_#{x}" )
            item = method_detail.operator_class.send("find_by_#{x}", value)
            if(item)
              record.send(operator + '=', item)
              break
            end
          rescue => e
            puts "ERROR: #{e.inspect}"
            if(x == Populator::insistent_method_list.last)
              raise "Populator failed to assign [#{value}] via moperator #{operator}" unless value.nil?
            end
          end
        end
      end
    end
    
    def assignment( operator, record, value )
      #puts "DEBUG: RECORD CLASS #{record.class}"
      op = operator + '=' unless(operator.include?('='))
    
      begin
        record.send(op, value)
      rescue => e
        Populator::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
            #puts "DEBUG: insistent_assignment: #{e.inspect}"
            if f == Populator::insistent_method_list.last
              puts  "I'm sorry I have failed to assign [#{value}] to #{operator}"
              raise "I'm sorry I have failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end
   
    
    # Default values and over rides can be provided in Ruby/YAML ???? config file.
    # 
    #  Format :
    #     
    #    Load Class:    (e.g Spree:Product)
    #     datashift_defaults:     
    #       value_as_string: "Default Project Value"  
    #       category: reference:category_002    
    #     
    #     datashift_overrides:    
    #       value_as_double: 99.23546
    #
    def configure_from(load_object_class, yaml_file)

      data = YAML::load( File.open(yaml_file) )
      
      # TODO - MOVE DEFAULTS TO OWN MODULE 
      # decorate the loading class with the defaults/ove rides to manage itself
      #   IDEAS .....
      #
      #unless(@default_data_objects[load_object_class])
      #
      #   @default_data_objects[load_object_class] = load_object_class.new
      
      #  default_data_object = @default_data_objects[load_object_class]
      
      
      # default_data_object.instance_eval do
      #  def datashift_defaults=(hash)
      #   @datashift_defaults = hash
      #  end
      #  def datashift_defaults
      #    @datashift_defaults
      #  end
      #end unless load_object_class.respond_to?(:datashift_defaults)
      #end
      
      #puts load_object_class.new.to_yaml
      
      logger.info("Read Datashift loading config: #{data.inspect}")
      
      if(data[load_object_class.name])
        
        logger.info("Assigning defaults and over rides from config")
        
        deflts = data[load_object_class.name]['datashift_defaults']
        default_values.merge!(deflts) if deflts
        
        ovrides = data[load_object_class.name]['datashift_overrides']
        override_values.merge!(ovrides) if ovrides
      end
      

    end
    
    # Set a value to be used to populate Model.operator
    # Generally over-rides will be used regardless of what value caller supplied.
    def set_override_value( operator, value )
      override_values[operator] = value
    end
    
    def override_values
      @override_values ||= {}
    end
    
    def override_value( operator )
      if(override_values[operator])
        @original_value_before_override = @current_value
      
        @current_value = @override_values[operator]
      end
    end
    
    # Set a default value to be used to populate Model.operator
    # Generally defaults will be used when no value supplied.
    def set_default_value(operator, value )
      default_values[operator] = value
    end
    
    def default_values
      @default_values ||= {}
    end
    
    # Return the default value for supplied operator
    def default_value(operator)
      default_values[operator]
    end
    

    def set_prefix( operator, value )
      prefixes[operator] = value
    end

    def prefix(operator)
      prefixes[operator]
    end

    def prefixes
      @prefixes ||= {}
    end
    
    def set_postfix(operator, value )
      postfixes[operator] = value
    end

    def postfix(operator)
      postfixes[operator]
    end
    
    def postfixes
      @postfixes ||= {}
    end
    
    
  end
  
end
