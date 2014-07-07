# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   This class provides info and access to groups of accessor methods,
#             grouped by AR model. 
#
#             Stores complete collection of MethodDetail instances per mapped class.
#             Provides high level find facilites to find a MethodDetail and to list out
#             operators per type (has_one, has_many, belongs_to, instance_method etc) 
#             and all possible operators, 

require 'to_b'

module DataShift

  # Stores MethodDetails for a class mapped by type
  class MethodDetailsManager

    attr_reader :method_details, :method_details_list
    attr_reader :managed_class_name
    
    def initialize( klass )
      @managed_class_name = klass.name
      @method_details = {}
      @method_details_list = {}
    end
    
    def add(method_details)
      #puts "DEBUG: MGR - Add {#method_details.operator_type}\n#{method_details.inspect}"
      @method_details[method_details.operator_type.to_sym] ||= {}
      
      # Mapped by Type and MethodDetail name
      @method_details[method_details.operator_type.to_sym][method_details.name] = method_details
      
      # Helper list of all available by type
      @method_details_list[method_details.operator_type.to_sym] ||= []
       
      @method_details_list[method_details.operator_type.to_sym] << method_details
      @method_details_list[method_details.operator_type.to_sym].uniq!
    end

    def <<(method_details)
      add(method_details)      
    end

    def find(name, type)
      method_details = get(type)
     
      method_details ? method_details[name] : nil
    end
    
    # type is expected to be one of MethodDetail::supported_types_enum
    # Returns all MethodDetail(s) for supplied type
    def get( type )
      @method_details[type.to_sym]
    end
    
    def get_list( type )
      @method_details_list[type.to_sym] || []
    end
    
    alias_method(:get_list_of_method_details, :get_list) 

    # Get list of the inbound or externally supplied names
    def get_names(type)
      get_list(type).collect { |md| md.name }
    end

    # Get list of Rails model operators   
    def get_operators(type)
      get_list(type).collect { |md| md.operator }
    end
    
    alias_method(:get_list_of_operators, :get_operators) 
     
    def available_operators
      method_details_list.values.flatten.collect(&:operator)
    end

    # A reverse map  showing all operators with their associated 'type'
    def available_operators_with_type
      h = {}
      method_details_list.each { |t, mds| mds.each do |v| h[v.operator] = t end }
    
      # this is meant to be more efficient that Hash[h.sort]
      sh = {}
      h.keys.sort.each do |k| sh[k] = h[k] end
      sh
    end
    
  end
  
end