class ModelMapper
  
  def self.class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name| 
      mod.const_get(class_name) 
    end 
  end 
  
end