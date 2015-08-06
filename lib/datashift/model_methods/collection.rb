# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Stores complete collection of ModelMethod instances per mapped class.
#             Provides high level find facilities to find a ModelMethod and to list out
#             operators per type (has_one, has_many, belongs_to, instance_method etc)
#             and all possible operators,
#
module DataShift

  module ModelMethods

    class Collection

      include DataShift::Logging
      extend DataShift::Logging

      attr_reader :managed_class

      # Hash of all available methods by type
      #   [:belongs_to] => [:user, :address]
      attr_accessor :by_optype

      # Map of operator => model_method
      # Grouped by :optype - [type][operator] = model_method
      #   e.g model_method = [:has_many][:projects]
      attr_accessor :by_optype_and_operator

      def initialize( klass )
        @managed_class = klass
        @by_optype_and_operator = {}
        @by_optype = {}
      end

      def managed_class_name
        @managed_class.name
      end

      alias_method :klass, :managed_class_name

      def insert(operator, type)
        mm = ModelMethod.new(managed_class, operator, type)
        add( mm )
        mm
      end

      def add(model_method)
        by_optype_and_operator[model_method.operator_type.to_sym] ||= {}

        # Mapped by Type and ModelMethod name   e.g [:belongs_to][:title]
        by_optype_and_operator[model_method.operator_type.to_sym][model_method.operator] = model_method

        # Helper list of all available by type  [:belongs_to]
        by_optype[model_method.operator_type.to_sym] ||= []

        by_optype[model_method.operator_type.to_sym] << model_method
        by_optype[model_method.operator_type.to_sym].uniq!
      end

      def <<(model_method)
        add(model_method)
      end

      # Search for  matching ModelMethod for given name across all types in supported_types_enum order
      def search(name)
        ModelMethod.supported_types_enum.each do |type|
          model_method = find(name, type)
          return model_method if(model_method)
        end

        nil
      end

      # Return matching ModelMethod for given name and specific type
      def find(name, type)
        by_optype_and_operator = get(type)

        by_optype_and_operator ? by_optype_and_operator[name] : nil
      end

      # Search for  matching ModelMethod for given name across Association types
      def find_association(name)
        ModelMethod.association_types_enum.each do |type|
          model_method = find(name, type)
          return model_method if(model_method)
        end

        nil
      end


      def get( klass )
        @by_optype_and_operator[klass.to_sym]
      end

      alias_method(:get_model_methods_by_class, :get)

      # Returns all ModelMethod(s) for supplied type e.g :belongs_to
      # type is expected to be one of ModelMethod::supported_types_enum
      def for_type( type )
        by_optype[type.to_sym] || []
      end

      alias_method :get_model_methods_by_type, :for_type

      # Get list of Rails model operators
      def get_operators(type)
        for_type(type).collect(&:operator)
      end

      alias_method(:get_list_of_operators, :get_operators)

      def available_operators
        by_optype.values.flatten.collect(&:operator)
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
