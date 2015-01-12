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
    attr_reader :current_col_type
    
    attr_reader :current_attribute_hash
    attr_reader :current_method_detail
    
    def initialize   
      @current_value = nil
      @current_method_detail = nil
      @original_value_before_override = nil
      @current_attribute_hash = {}

    end
    
    # Convert DSL string forms into a hash
    # e.g
    # 
    #  "{:name => 'autechre'}" =>   Hash['name'] = autechre'
    #  "{:cost_price => '13.45', :price => 23,  :sale_price => 4.23 }"
    
    def self.string_to_hash( str )
      h = {}
      str.gsub(/[{}:]/,'').split(', ').map do |e| 
        k,v = e.split('=>')
        
        k.strip!
        v.strip!
        
        if( v.match(/['"]/) )
          h[k] = v.gsub(/["']/, '')
        elsif( v.match(/^\d+$|^\d*\.\d+$|^\.\d+$/) )
          h[k] = v.to_f
        else
          h[k] = v
        end
        h
      end
   
      h
    end
    
    # Set member variables to hold details, value and optional attributes,
    # to be set on the 'value' once created
    # 
    # Check supplied value, validate it, and if required :
    #   set to provided default value
    #   prepend any provided prefixes 
    #   add any provided postfixes
    def prepare_data(method_detail, value)

      raise NilDataSuppliedError.new("No method detail supplied for prepare_data") unless(method_detail)
     
      begin
        @prepare_data_const_regexp ||= Regexp.new( Delimiters::attribute_list_start + ".*" + Delimiters::attribute_list_end)
              
        # Rails 4 - query no longer returns an array
        if( value.is_a? ActiveRecord::Relation )
          @current_value = value.to_a
        else
          @current_value = value.to_s
          
          attribute_hash = @current_value.slice!(@prepare_data_const_regexp)
          
          if(attribute_hash)  
            #@current_value.chop!    # the slice seems to add an extra space/eol
            @current_attribute_hash = Populator::string_to_hash( attribute_hash )
            logger.info "Populator for #{@current_value} has attributes #{@current_attribute_hash.inspect}"
          end
        end
      
        @current_attribute_hash ||= {}
       
        @current_method_detail = method_detail
      
        @current_col_type = @current_method_detail.col_type
      
        operator = method_detail.operator
      
        override_value(operator)
        
        if((value.nil? || value.to_s.empty?) && default_value(operator))
          @current_value = default_value(operator)
        end
      
        @current_value = "#{prefix(operator)}#{@current_value}" if(prefix(operator))
        @current_value = "#{@current_value}#{postfix(operator)}" if(postfix(operator))

      rescue => e
        logger.error("populator failed to prepare data supplied for operator #{method_detail.operator}")
        logger.error("populator stacktrace: #{e.backtrace.join('\\n')}")
      end
      
      return @current_value, @current_attribute_hash
    end
    
    def prepare_and_assign(method_detail, record, value)
      
      prepare_data(method_detail, value) 
       
      assign(record)
      
    end
    
    def assign(record)
     
      raise NilDataSuppliedError.new("No method detail - cannot assign data") unless(current_method_detail)
       
      operator = current_method_detail.operator

      logger.debug("Populator assigning data via #{current_method_detail.operator}")
              
      if( current_method_detail.operator_for(:belongs_to) )
 
        insistent_belongs_to(current_method_detail, record, current_value)

      elsif( current_method_detail.operator_for(:has_many) )

        # The include? check is best I can come up with right now .. to handle module/namespaces
        # TODO - can we determine the real class type of an association
        # e.g given a association taxons, which operator.classify gives us Taxon, but actually it's Spree::Taxon
        # so how do we get from 'taxons' to Spree::Taxons ? .. check if further info in reflect_on_all_associations

        if(current_value.is_a?(Array) || current_value.class.name.include?(operator.classify))
          record.send(operator) << current_value
        else
          logger.error "Cannot assign to has_many operator [#{operator}] - #{current_value} (#{current_value.class})"
        end

      elsif( current_method_detail.operator_for(:has_one) )

        #puts "DEBUG : HAS_MANY :  #{@name} : #{operator}(#{operator_class}) - Lookup #{@current_value} in DB"
        if(current_value.is_a?(current_method_detail.operator_class))
          record.send(operator + '=', current_value)
        else
          logger.error("ERROR #{current_value.class} - Not expected type for has_one #{operator} - cannot assign")
          # TODO -  Not expected type - maybe try to look it up somehow ?"
          #insistent_has_many(record, @current_value)
        end

      elsif( current_method_detail.operator_for(:assignment) && current_col_type)
        logger.debug("Assignging #{current_value} => [#{operator}] (CAST 2 TYPE  #{current_col_type.type_cast( current_value ).inspect})")
        
        record.send( operator + '=' , current_method_detail.col_type.type_cast( current_value ) )

      elsif( current_method_detail.operator_for(:assignment) )
        logger.debug("Brute force assignment of value  #{current_value} => [#{operator}]")
        # brute force case for assignments without a column type (which enables us to do correct type_cast)
        # so in this case, attempt straightforward assignment then if that fails, basic ops such as to_s, to_i, to_f etc
        insistent_assignment(record, current_value, operator)
      else
        puts "WARNING: No assignment possible on #{record.inspect} using [#{operator}]"
        logger.error("WARNING: No assignment possible on #{record.inspect} using [#{operator}]")
      end
    end
    
    def insistent_assignment(record, value, operator)
      
      op = operator + '=' unless(operator.include?('='))

      begin
        record.send(op, value)
      rescue => e

        Populator::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
            if f == Populator::insistent_method_list.last
              logger.error(e.inspect)
              logger.error("Failed to assign [#{value}] via operator #{operator}")
              raise "Failed to assign [#{value}] to #{operator}" unless value.nil?
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

        Populator::insistent_find_by_list.each do |x|
          begin
 
            # puts "DEBUG : insistent_belongs_to => #{method_detail.operator_class.respond_to?( "find_by_#{x}" )}"
             
            next unless method_detail.operator_class.respond_to?("where")

            item = method_detail.operator_class.where(x => value).first_or_create

            if(item)
              record.send(operator + '=', item)
              break
            end
          rescue => e
            logger.error(e.inspect)
            logger.error("Failed attempting to find belongs_to for #{method_detail.pp}")
            if(x == Populator::insistent_method_list.last)
              raise "Populator failed to assign [#{value}] via operator #{operator}" unless value.nil?
            end
          end
        end
        
      end
    end
    
    def assignment( operator, record, value )

      op = operator + '=' unless(operator.include?('='))
    
      begin
        record.send(op, value)
      rescue => e
        Populator::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
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

      data = YAML::load( ERB.new( IO.read(yaml_file) ).result )


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
      
      logger.info("Setting Populator defaults: #{data.inspect}")
      
      if(data[load_object_class.name])

        deflts = data[load_object_class.name]['datashift_defaults']
        default_values.merge!(deflts) if deflts

        logger.info("Set Populator default_values: #{default_values.inspect}")
        
        ovrides = data[load_object_class.name]['datashift_overrides']
        override_values.merge!(ovrides) if ovrides
        logger.info("Set Populator overrides: #{override_values.inspect}")
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
