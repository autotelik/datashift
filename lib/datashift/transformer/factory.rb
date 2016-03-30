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
#     DataShift::transformer.factory do |factory|
#        factory.set_default_on(Project, 'value_as_string', 'default text' )
#     end
#
#   This global factory is automatically utilised by the default Populator
#   during data load.
#
#   If passed an optional locale, rules for other
#   languages can be specified. If not specified, defaults to <tt>:en</tt>.
#
#
# WORK In PROGRESS

require 'thread_safe'

module DataShift

  module Transformer

    extend self

    Struct.new('Substitution', :pattern, :replacement)

    class Factory

      @__instance__ = ThreadSafe::Cache.new

      def self.instance(locale = :en)
        @__instance__[locale] ||= new
      end

      attr_reader :defaults, :overrides, :substitutions
      attr_reader :prefixs, :postfixs

      def initialize
        clear
      end

      def clear
        @defaults = {}
        @overrides = {}
        @substitutions = {}
        @prefixs = {}
        @postfixs = {}
      end

      def defaults_for( klass )
        defaults[klass] ||= {}
        defaults[klass]
      end

      def default( method_binding )
        defaults_for(method_binding.klass)[method_binding.operator]
      end

      def has_default?( method_binding )
        defaults_for(method_binding.klass).key?(method_binding.operator)
      end

      def substitutions_for( klass )
        substitutions[klass] ||= {}
        substitutions[klass]
      end

      def substitution( method_binding )
        substitutions_for(method_binding.klass)[method_binding.operator]
      end

      def has_substitution?( method_binding )
        substitution_for(method_binding.klass).key?(method_binding.operator)
      end

      def overrides_for(klass)
        overrides[klass] ||= {}
        overrides[klass]
      end

      def override( method_binding )
        overrides_for(method_binding.klass)[method_binding.operator]
      end

      def has_override?( method_binding )
        overrides_for(method_binding.klass).key?(method_binding.operator)
      end

      def prefixs_for(klass)
        prefixs[klass] ||= {}
        prefixs[klass]
      end

      def prefix( method_binding )
        prefixs_for(method_binding.klass)[method_binding.operator]
      end

      def has_prefix?( method_binding )
        prefixs_for(method_binding.klass).key?(method_binding.operator)
      end

      def postfixs_for(klass)
        postfixs[klass] ||= {}
        postfixs[klass]
      end

      def postfix( method_binding )
        postfixs_for(method_binding.klass)[method_binding.operator]
      end

      def has_postfix?( method_binding )
        postfixs_for(method_binding.klass).key?(method_binding.operator)
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
          Struct.new('Substitution', :pattern, :replacement)[rule, replacement]
      end

      def set_prefix( method_binding, value)
        prefixs_for(method_binding.klass)[method_binding.operator] = value
      end

      def set_postfix( method_binding, value)
        postfixs_for(method_binding.klass)[method_binding.operator] = value
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
        substitutions_for(klass)[operator] =
          Struct.new('Substitution', :pattern, :replacement)[rule, replacement]
      end

      def set_prefix_on(klass, operator, value)
        prefixs_for(klass)[operator] = value
      end

      def set_postfix_on(klass, operator, value)
        postfixs_for(klass)[operator] = value
      end

    end

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
    #     substitutions
    #     prefixs
    #     postfixs
  end

  def set_postfix_on
    #
    def configure_from(load_object_class, yaml_file)

      # TODO

      data = YAML.load( ERB.new( IO.read(yaml_file) ).result )

      logger.info("Setting up Transformations : #{data.inspect}")

      klass = load_object_class.name

      keyed_on_class = data[klass]

      if keyed_on_class

        defaults = keyed_on_class['datashift_defaults']

        defaults.each do |_operator, default_value|
          DataShift::Transformer.factory.defaults_for(klass)[method_binding.operator] = default_value
        end if defaults & defaults.is_a(Hash)

=begin
        def set_default_on(klass, operator, default_value )
          # puts "In set_default_on ", klass, operator, default_value
          defaults_for(klass)[operator] = default_value
        end

        # use regardless of whether inbound data supplied
        def set_override_on(klass, operator, value )
          overrides_for(klass)[operator] = value
        end

        def set_substitution_on(klass, operator, rule, replacement )
          substitutions_for(klass)[operator] =
            Struct.new('Substitution', :pattern, :replacement)[rule, replacement]
        end

        def set_prefix_on(klass, operator, value)
          prefixs_for(klass)[operator] = value
        end

        def set_postfix_on(klass, operator, value)
          postfixs_for(klass)[operator] = value
        end
=end


        #         overrides = keyed_on_class['datashift_overrides']
        #
        #         subs = keyed_on_class['datashift_substitutions']
        #
        #         subs.each do |o, sub|
        #           # TODO support single array as well as multiple [[..,..], [....]]
        #           sub.each { |tuple| set_substitution(o, tuple) }
        #         end if(subs)
      end

      proteced

      def get_method_name( binding )
        binding.is_a?(MethodBinding) ? method_binding.operator : binding
      end

    end ## class

  end
end
