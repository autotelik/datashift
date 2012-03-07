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

    attr_reader :method_details
    
    def initialize( klass )
      @parent_class = klass
      @method_details = {}
      @method_details_list = {}
    end
    
    def add(method_details)
      @method_details[method_details.operator_type.to_intern] ||= {}
      @method_details_list[method_details.operator_type.to_intern] ||= []
       
      @method_details[method_details.operator_type.to_intern][method_details.name] = method_details
      @method_details_list[method_details.operator_type.to_intern] << method_details
      @method_details_list[method_details.operator_type.to_intern].uniq!
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
      @method_details[type.to_intern]
    end
    
    def get_list( type )
      @method_details_list[type.to_intern]
    end
    
  end
  
end