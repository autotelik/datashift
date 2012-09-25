# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   This class provides info and access to groups of accessor methods,
#             grouped by AR model. 
#
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
      @method_details[method_details.operator_type.to_sym] ||= {}
      @method_details_list[method_details.operator_type.to_sym] ||= []
       
      @method_details[method_details.operator_type.to_sym][method_details.name] = method_details
      @method_details_list[method_details.operator_type.to_sym] << method_details
      @method_details_list[method_details.operator_type.to_sym].uniq!
    end

    def <<(method_details)
      add(method_details)      
    end

    def find(name, type)
      method_details = get(type)
     
      method_details ?  method_details[name] : nil
    end
    
    # type is expected to be one of MethodDetail::supportedtype_enum
    def get( type )
      @method_details[type.to_sym]
    end
    
    def get_list( type )
      @method_details_list[type.to_sym] || []
    end
    
    alias_method(:get_list_of_method_details, :get_list) 
    
    def get_operators( op_type )
      get_list(op_type).collect { |md| md.operator }
    end
    
    alias_method(:get_list_of_operators, :get_list) 
     
    def all_available_operators
      method_details_list.values.flatten.collect(&:operator)
    end
    
  end
  
end