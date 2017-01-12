# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Maps transformations to internal Class methods.
#
#             Stores :
#               defaults
#               substitutions
#               over rides
#               prefixes
#               postfixes
#
# These are keyed on the associated method binding ** OPERATOR ** which is
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
require 'active_support/inflector'

# Helper class
Struct.new('Substitution', :pattern, :replacement)

module DataShift

  module Transformation

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

      TRANSFORMERS_HASH_INSTANCE_NAMES = [:default, :override, :substitution, :prefix, :postfix].freeze

      include DataShift::Logging

      @__instance__ = ThreadSafe::Cache.new

      def self.instance(locale = :en)
        @__instance__[locale] ||= new
      end

      def self.reset(locale = :en)
        @__instance__[locale] = new
      end

      attr_reader :defaults, :overrides, :substitutions
      attr_reader :prefixes, :postfixes

      def initialize
        clear
      end

      def clear
        TRANSFORMERS_HASH_INSTANCE_NAMES.each do|h|
          instance_variable_set("@#{h.to_s.pluralize}", ActiveSupport::HashWithIndifferentAccess.new({}))
        end
      end

      # Default values and over rides per class can be provided in YAML config file.
      #
      # The locale_key for situations where the Class one level down, for example as per our own
      # Template for Datashift Import/Export Configuration which has format :
      #
      # key:
      #  klass:
      #
      def configure_from(load_object_class, yaml_file, locale_key = 'data_flow_schema')

        data = YAML.load( ERB.new( IO.read(yaml_file) ).result )

        class_name = load_object_class.name

        data = data[locale_key] if(locale_key)

        configure_from_yaml(load_object_class, data[class_name]) if(data[class_name])
      end

      def configure_from_yaml(load_object_class, yaml)

        setter_method_map = {
          defaults: :set_default_on,
          overrides: :set_override_on,
          substitutions: :set_substitution_on_list,
          prefixes: :set_prefix_on,
          postfixes: :set_postfix_on
        }

        setter_method_map.each do |key, call|
          settings = yaml[key.to_s]

          next unless settings && settings.is_a?(Hash)
          settings.each do |operator, value|
            logger.info("Configuring Transform [#{key}] for [#{operator.inspect}] to [#{value}]")
            send( call, load_object_class, operator, value)
          end
        end

      end

      def hash_key(key)
        return key if(key.is_a? String)
        return key.class_name if(key.is_a? MethodBinding)
        key.name # Class name
      end

      TRANSFORMERS_HASH_INSTANCE_NAMES.each do |tname|

        plural_tname = tname.to_s.pluralize

        # NAME  : defaults_for(key)
        #
        # Return the defaults for the supplied KEY (Class or String)
        #
        class_eval <<-end_eval
          def #{plural_tname}_for(key)
           #{plural_tname}[hash_key(key)] ||= new_hash_instance
          end
        end_eval

        # NAME :  default?( method_binding )
        #
        # Is there a transform for this MethodBinding ?
        #
        class_eval <<-end_eval
          def #{tname}?( method_binding )
            #{plural_tname}_for(method_binding).key?(method_binding.operator)
          end
        end_eval

        # RETURN a transform for this MethodBinding
        #
        # Example : default( method_binding )
        #
        class_eval <<-end_eval
          def #{tname}( method_binding )
           get_#{tname}_on(method_binding, method_binding.operator)
          end
        end_eval

        # RETURN a transform for this key/operator pair
        #
        # Example : get_default_on(key, operator)
        #
        class_eval <<-end_eval
          def get_#{tname}_on(key, operator)
            #{plural_tname}_for(key)[operator]
          end
        end_eval

        next if(tname == :substitution)

        # NAME : set_default_on(key, operator, default_value )
        #
        # Set the defaults for the supplied KEY (Class or String) and Operator
        #
        class_eval <<-end_eval
          def set_#{tname}_on(key, operator, default_value )
            #{plural_tname}_for(key)[operator] = default_value
          end
        end_eval

        # Example : set_default(method_binding, default_value )
        #
        define_method("set_#{tname}") do |method_binding, default_value|
          send("set_#{tname}_on", method_binding, method_binding.operator, default_value)
        end

      end

      def set_substitution( method_binding, rule, replacement )
        set_substitution_on( method_binding, method_binding.operator, rule, replacement)
      end

      def set_substitution_on(key, operator, rule, replacement )
        substitutions_for(key)[operator] = Struct::Substitution.new(rule, replacement)
      end

      private

      def set_substitution_on_list(key, operator, list )
        substitutions_for(key)[operator] = Struct::Substitution.new(list[0], list[1])
      end

      def new_hash_instance
        ActiveSupport::HashWithIndifferentAccess.new {}
      end

    end

  end ## class

end
