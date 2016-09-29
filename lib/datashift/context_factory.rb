# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Creates, configures and caches objects for use by current context
#
# SomeModule::MyAboutToBeLoadedClass:
#     datashift_defaults:
#       password: 'ns_spree_123'
#       available_on: <%= Time.now.to_s(:db) %>
#       shipping_category: 'Default'
#       phone: '9999999999'
#
#     datashift_substitutions:
#       order: ['#', 'NUMBER-']
#       "Lineitems": ['10PAC', '5PAC']
#
#     datashift_populators:
#       promo_code: PromoCodePopulator
#
module DataShift
  class ContextFactory

    class << self; attr_accessor :config end

    # Clear out map of operators to populator Class
    def self.clear_populators
      populators.clear
    end

    # Return map of operators to populator Class
    def self.populators
      @populators ||= {}
    end

    # Options :
    #    formatter
    #    populator
    #
    def self.configure(load_object_class, yaml_file)

      @config = YAML.load( ERB.new( IO.read(yaml_file) ).result )

      @config[:datashift_populators].each do |_operator, type|
        populator = ::Object.const_get(type).new

        populator.configure_from(load_object_class, yaml_file)

        populators[@config[:datashift_populators]]
      end if @config[:datashift_populators]

    end

    # Move to CONTEXT
    #     @populator = if(options[:populator].is_a?(String))
    #                    ::Object.const_get(options[:populator]).new
    #                  elsif(options[:populator].is_a?(Class))
    #                    options[:populator].new
    #                  else
    #                    DataShift::Populator.new
    #                  end

    # Set a Populator to be used against an INBOUND operator

    class << self
      attr_writer :global_populator_class
    end

    def self.global_populator_class
      @global_populator_class || DataShift::Populator
    end

    def self.set_populator(method_binding, klass)
      operator = method_binding.is_a?(DataShift::MethodBinding) ? method_binding.operator : method_binding
      populators[operator] = klass
    end

    def self.get_populator(method_binding)

      if(populators.key?(method_binding.operator))
        return populators[method_binding.operator].new
      end unless method_binding.nil? || method_binding.invalid?

      global_populator_class.new
    end

  end
end
