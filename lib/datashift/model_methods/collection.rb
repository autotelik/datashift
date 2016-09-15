# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Stores complete collection of ModelMethod instances per mapped class.
#
#             Mapped to association types as defined by ModelMethod::supported_types_enum

#             Provides high level find facilities to find a ModelMethod and to list out
#             operators per type (has_one, has_many, belongs_to, instance_method etc)
#             and all possible operators,
#
module DataShift

  module ModelMethods

    class Collection

      include DataShift::Logging
      extend DataShift::Logging

      include Enumerable

      attr_reader :managed_class

      # Hash of all available methods by type
      #    [:assignment] => [:id, :name], [:belongs_to] => [:user, :address]
      #
      attr_accessor :by_optype

      attr_accessor :model_method_list

      extend Forwardable

      def_delegators :@model_method_list, [], :sort, :sort!, :first, :last

      def initialize( klass )
        @managed_class = klass
        @model_method_list = []
        @by_optype = {}
      end

      def managed_class_name
        @managed_class.name
      end

      alias klass managed_class_name

      def insert(operator, type)
        mm = ModelMethod.new(managed_class, operator, type)
        add( mm )
        mm
      end

      def add(model_method)
        model_method_list << model_method

        maintain_by_optype_helper model_method
      end

      def maintain_by_optype_helper( model_method )
        # Helper list of all available by type  [:belongs_to]
        by_optype[model_method.operator_type.to_sym] ||= []
        by_optype[model_method.operator_type.to_sym] << model_method
        by_optype[model_method.operator_type.to_sym].uniq!
      end

      def <<(model_method)
        add(model_method)
      end

      def push(model_method)
        add(model_method)
      end

      def unshift(model_method)
        model_method_list.unshift model_method
        maintain_by_optype_helper model_method
      end

      def each
        model_method_list.each { |mm| yield(mm) }
      end

      # Search for  matching ModelMethod for given name across all types in supported_types_enum order
      def search(name)
        ModelMethod.supported_types_enum.each do |type|
          model_method = find_by_name_and_type(name, type)
          return model_method if model_method
        end

        nil
      end

      # Return matching ModelMethod for given name and specific type
      def find_by_name_and_type(name, type)
        by_optype = model_method_list.find_all { |mm| mm.operator_type? type }

        by_optype.find { |mm| mm.operator? name }
      end

      # Search for  matching ModelMethod for given name across Association types
      def find_association(name)
        ModelMethod.association_types_enum.each do |type|
          model_method = find_by_name_and_type(name, type)
          return model_method if model_method
        end

        nil
      end

      # Returns all ModelMethod(s) for supplied type e.g :belongs_to
      # type is expected to be one of ModelMethod::supported_types_enum
      def for_type( type )
        model_method_list.find_all { |mm| mm.operator_type? type }
      end

      # Get list of Rails model operators
      def get_operators(type)
        for_type(type).collect(&:operator)
      end

      def available_operators
        model_method_list.collect(&:operator)
      end

      # A reverse map  showing all operators with their associated 'type'
      def available_operators_with_type
        h = {}
        by_optype.each { |t, mms| mms.each { |v| h[v.operator] = t } }

        # this is meant to be more efficient that Hash[h.sort]
        sh = {}
        h.keys.sort.each { |k| sh[k] = h[k] }
        sh
      end
    end

  end
end
