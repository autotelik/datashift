# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Stores complete collection of ModelMethod instances per mapped class.
#             Provides high level find facilities to find a ModelMethod and to list out
#             operators per type (has_one, has_many, belongs_to, instance_method etc) 
#             and all possible operators,
#
module DataShift

  module ModelMethods

    class Manager

      include DataShift::Logging
      extend DataShift::Logging

      attr_reader :managed_class

      attr_accessor :model_methods, :model_methods_list

      def initialize( klass )
        @managed_class = klass
        @model_methods = {}
        @model_methods_list = {}
      end

      def add(model_method)
        model_methods[model_method.operator_type.to_sym] ||= {}

        # Mapped by Type and MethodDetail name
        model_methods[model_method.operator_type.to_sym][model_method.operator] = model_method

        # Helper list of all available by type
        model_methods_list[model_method.operator_type.to_sym] ||= []

        @model_methods_list[model_method.operator_type.to_sym] << model_method
        @model_methods_list[model_method.operator_type.to_sym].uniq!
      end

      def <<(model_method)
        add(model_method)
      end

      def find(name, type)
        model_methods = get(type)

        model_methods ? model_methods[name] : nil
      end

      # type is expected to be one of ModelMethod::supported_types_enum
      # Returns all ModelMethod(s) for supplied type e.g :belongs_to
      def get( type )
        @model_methods[type.to_sym]
      end

      alias_method(:get_model_methods_by_type, :get)

      def get_list( type )
        @model_methods_list[type.to_sym] || []
      end

      alias_method(:get_list_of_model_methods, :get_list)

      # Get list of Rails model operators
      def get_operators(type)
        get_list(type).collect { |mm| mm.operator }
      end

      alias_method(:get_list_of_operators, :get_operators)

      def available_operators
        model_methods_list.values.flatten.collect(&:operator)
      end

      # A reverse map  showing all operators with their associated 'type'
      def available_operators_with_type
        h = {}
        model_methods_list.each { |t, mms| mms.each do |v| h[v.operator] = t end }

        # this is meant to be more efficient that Hash[h.sort]
        sh = {}
        h.keys.sort.each do |k| sh[k] = h[k] end
        sh
      end
    end


    # HIGH LEVEL COLLECTION METHODS

    class Catalogue

      include DataShift::Logging
      extend DataShift::Logging

      # Create simple picture of all the operator names for assignment available on a domain model,
      # grouped by type of association (includes belongs_to and has_many which provides both << and = )
      # Options:
      #   :reload => clear caches and re-perform  lookup
      #   :instance_methods => if true include instance method type 'setters' as well as model's pure columns
      #
      def self.find_methods(klass, options = {} )

        raise "Cannot find operators supplied klass nil #{klass}" if(klass.nil?)

        register(klass)

        logger.debug("ModelMethodsManager - building operators information for #{klass}")

        # Find the has_many associations which can be populated via <<
        if( options[:reload] || has_many[klass].nil? )
          has_many[klass] = klass.reflect_on_all_associations(:has_many).map { |i| i.name.to_s }
          klass.reflect_on_all_associations(:has_and_belongs_to_many).inject(has_many[klass]) { |x,i| x << i.name.to_s }
        end

        # Find the belongs_to associations which can be populated via  Model.belongs_to_name = OtherArModelObject
        if( options[:reload] || belongs_to[klass].nil? )
          belongs_to[klass] = klass.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }
        end

        # Find the has_one associations which can be populated via  Model.has_one_name = OtherArModelObject
        if( options[:reload] || has_one[klass].nil? )
          has_one[klass] = klass.reflect_on_all_associations(:has_one).map { |i| i.name.to_s }
        end

        # Find the model's column associations which can be populated via xxxxxx= value
        # Note, not all reflections return method names in same style so we convert all to
        # the raw form i.e without the '='  for consistency
        if( options[:reload] || assignments[klass].nil? )

          assignments[klass] = klass.column_names

          # get into consistent format with other assignments names i.e remove the = for now
          assignments[klass] += setters(klass).map{|i| i.gsub(/=/, '')} if(options[:instance_methods])

          # Now remove all the associations
          assignments[klass] -= has_many[klass]   if(has_many[klass])
          assignments[klass] -= belongs_to[klass] if(belongs_to[klass])
          assignments[klass] -= has_one[klass]    if(has_one[klass])

          # TODO remove assignments with id
          # assignments => tax_id  but already in belongs_to => tax

          assignments[klass].uniq!

          assignments[klass].each do |assign|
            column_types[klass] ||= {}
            column_def = klass.columns.find{ |col| col.name == assign }
            column_types[klass].merge!( assign => column_def) if column_def
          end
        end
      end

      def self.methods_for?(klass )
        methods_for.include?(klass)
      end

      def self.clear
        belongs_to.clear
        has_many.clear
        assignments.clear
        column_types.clear
        has_one.clear
      end

      def self.belongs_to
        @belongs_to ||={}
        @belongs_to
      end

      def self.has_many
        @has_many ||= {}
        @has_many
      end

      def self.has_one
        @has_one ||= {}
        @has_one
      end

      def self.assignments
        @assignments ||= {}
        @assignments
      end

      def self.column_types
        @column_types ||= {}
        @column_types
      end


      def self.belongs_to_for(klass)
        belongs_to[klass] || []
      end

      def self.has_many_for(klass)
        has_many[klass] || []
      end

      def self.has_one_for(klass)
        has_one[klass] || []
      end

      def self.assignments_for(klass)
        assignments[klass] || []
      end

      def self.column_type_for(klass, column)
        column_types[klass] ?  column_types[klass][column] : []
      end

  private

      def self.methods_for
        @methods_for ||= []
      end

      def self.register(klass)
        methods_for << klass
        methods_for.uniq!
      end

    end

  end
end