class ModelMapper
  
  # Helper to deal with modules/namespaced classes
  # return the base class from a string.
  # Support getting class from modules e.g "Spree::Property"
  # Raises exception if no such class found
  def self.const_get_from_string(str)
    str.split('::').inject(Object) do |mod, class_name| 
      mod.const_get(class_name) 
    end 
  end 
  
  
  # Similar to const_get_from_string except this version
  # returns nil if no such class found
  # Support modules e.g "Spree::Property"
  # 
  def self.class_from_string( str )
      begin
        ModelMapper::const_get_from_string(str)  #Kernel.const_get(model)
      rescue NameError => e
       return nil
      end
  end
  
end