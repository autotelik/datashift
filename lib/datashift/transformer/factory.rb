# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Maps transformations to internal Class methods.
#
#             Stores :
#               substitutions
#               over rides
#               prefixes
#               postfixes
#
# These are keyed on the associated method binding operator, which is
# essentially the method call/active record column on the class.
#
# Clients can decide exactly how these can be applied to incoming data.
#
# Usage::
#
#   Provides a singleton instance of Transformations::Factory
#   so you can specify additional transforms in .rb config as follows :
#
# IN : my_transformations.rb
#
#     DataShift::Transformer.factory do |factory|
#        factory.set_default_on(Project, 'value_as_string', 'default text' )
#     end
#
#   This global factory is automatically utilised by the default Populator
#   during data load.
#
#   If passed an optional locale, rules for other
#   languages can be specified. If not specified, defaults to <tt>:en</tt>.
#
require 'thread_safe'

# Helper class
Struct.new('Substitution', :pattern, :replacement)

module DataShift

  module Transformer

    extend self

    # Yields a singleton instance of Transformations::Factory
    # so you can specify additional transforms in .rb config
    # If passed an optional locale, rules for other
    # languages can be specified. If not specified, defaults to <tt>:en</tt>.
    #
    # Only rules for English are provided.
    #
    def factory(locale = :en)
      if block_given?
        yield Factory.instance(locale)
      else
        Factory.instance(locale)
      end
    end

    class Factory

      include DataShift::Logging

      @__instance__ = ThreadSafe::Cache.new

      def self.instance(locale = :en)
        @__instance__[locale] ||= new
      end

      attr_reader :defaults, :overrides, :substitutions
      attr_reader :prefixes, :postfixes

      def initialize
        clear
      end

      def clear
        @defaults = new_hash_instance
        @overrides = new_hash_instance
        @substitutions = new_hash_instance
        @prefixes = new_hash_instance
        @postfixes = new_hash_instance
      end

      # Default values and over rides per class can be provided in YAML config file.
      #
      def configure_from(load_object_class, yaml_file)

        data = YAML.load( ERB.new( IO.read(yaml_file) ).result )

        logger.info("Setting up Transformations : #{data.inspect}")

        klass = load_object_class.name

        config_for_class = data[klass]

        if(config_for_class)

          method_map = {
            defaults: :set_default_on,
            overrides: :set_override_on,
            substitutions: :set_substitution_on_list,
            prefixes: :set_prefix_on,
            postfixes: :set_postfix_on
          }

          method_map.each do |key, call|
            settings = config_for_class[key.to_s]

            settings.each do |operator, value|
              send( call, load_object_class, operator, value)
            end if(settings && settings.is_a?(Hash))
          end

        end
      end

      def defaults_for( klass )
        defaults[klass] ||= new_hash_instance
        defaults[klass]
      end

      def default( method_binding )
        defaults_for(method_binding.klass)[method_binding.operator]
      end

      def has_default?( method_binding )
        defaults_for(method_binding.klass).key?(method_binding.operator)
      end

      # SUBSTITUTIONS

      def substitutions_for( klass )
        substitutions[klass] ||= new_hash_instance
        substitutions[klass]
      end

      def substitution( method_binding )
        substitutions_for(method_binding.klass)[method_binding.operator]
      end

      def has_substitution?( method_binding )
        substitution_for(method_binding.klass).key?(method_binding.operator)
      end

      # OVER RIDES
      def overrides_for(klass)
        overrides[klass] ||= new_hash_instance
        overrides[klass]
      end

      def override( method_binding )
        overrides_for(method_binding.klass)[method_binding.operator]
      end

      def has_override?( method_binding )
        overrides_for(method_binding.klass).key?(method_binding.operator)
      end

      def prefixes_for(klass)
        prefixes[klass] ||= new_hash_instance
        prefixes[klass]
      end

      def prefix( method_binding )
        prefixes_for(method_binding.klass)[method_binding.operator]
      end

      def has_prefix?( method_binding )
        prefixes_for(method_binding.klass).key?(method_binding.operator)
      end

      def postfixes_for(klass)
        postfixes[klass] ||= new_hash_instance
        postfixes[klass]
      end

      def postfix( method_binding )
        postfixes_for(method_binding.klass)[method_binding.operator]
      end

      def has_postfix?( method_binding )
        postfixes_for(method_binding.klass).key?(method_binding.operator)
      end

      # use when no inbound data supplied
      def set_default(method_binding, default_value )
        defaults_for(method_binding.klass)[method_binding.operator] = default_value
      end

      # use regardless of whether inbound data supplied
      def set_override( method_binding, value )
        overrides_for(method_binding.klass)[method_binding.operator] = value
      end

      def set_substitution( method_binding, rule, replacement )
        substitutions_for(method_binding.klass)[method_binding.operator] =
          Struct::Substitution.new(rule, replacement)
      end

      def set_prefix( method_binding, value)
        prefixes_for(method_binding.klass)[method_binding.operator] = value
      end

      def set_postfix( method_binding, value)
        postfixes_for(method_binding.klass)[method_binding.operator] = value
      end

      # Class based versions

      def set_default_on(klass, operator, default_value )
        # puts "In set_default_on ", klass, operator, default_value
        defaults_for(klass)[operator] = default_value
      end

      # use regardless of whether inbound data supplied
      def set_override_on(klass, operator, value )
        overrides_for(klass)[operator] = value
      end

      def set_substitution_on(klass, operator, rule, replacement )
        substitutions_for(klass)[operator] = Struct::Substitution.new(rule, replacement)
      end

      def set_prefix_on(klass, operator, value)
        prefixes_for(klass)[operator] = value
      end

      def set_postfix_on(klass, operator, value)
        postfixes_for(klass)[operator] = value
      end

      private

      def set_substitution_on_list(klass, operator, list )
        substitutions_for(klass)[operator] = Struct::Substitution.new(list[0], list[1])
      end

      def new_hash_instance
        ActiveSupport::HashWithIndifferentAccess.new {}
      end

    end

  end ## class

end
