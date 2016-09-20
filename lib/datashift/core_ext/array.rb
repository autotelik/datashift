Array.class_eval do

  ARRAY_FWDABLE_EXCLUDED_METHODS = [
    :class, :singleton_class, :clone, :dup, :initialize_dup, :initialize_clone,
    :freeze, :methods, :singleton_methods, :protected_methods, :private_methods, :public_methods,
    :instance_variables, :instance_variable_get, :instance_variable_set, :instance_variable_defined?,
    :instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, :respond_to?, :respond_to_missing?,
    :extend, :display, :method, :public_method, :define_singleton_method, :object_id, :equal?,
    :instance_eval, :instance_exec, :__send__, :__id__
  ].freeze

  def self.delegated_methods_for_fwdable
    Array.instance_methods - ARRAY_FWDABLE_EXCLUDED_METHODS
  end
end
