# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Catalogues all possible methods for populating data on a class
#
#             Provides high level find facilities to perform cataloguing on a class
#             and retrieving operators per type (has_one, has_many, belongs_to, instance_method etc)
#
module DataShift

  module ModelMethods

    # HIGH LEVEL COLLECTION METHODS

    class Catalogue

      include DataShift::Logging
      extend DataShift::Logging

      def self.catalogued?(klass)
        catalogued.include?(klass)
      end

      def self.size
        catalogued.size
      end

      # Create simple picture of all the operator names for assignment available on a domain model,
      # grouped by type of association (includes belongs_to and has_many which provides both << and = )
      # Options:
      #   :reload => clear caches and re-perform  lookup
      #   :instance_methods => if true include instance method type 'setters' as well as model's pure columns
      #
      def self.populate(klass, options = {} )

        raise "Cannot find operators supplied klass nil #{klass}" if klass.nil?

        register(klass)

        logger.debug("Catalogue - building operators information for #{klass}")

        # Find the has_many associations which can be populated via <<
        if options[:reload] || has_many[klass].nil?
          if Module.const_defined?(:Mongoid)
            has_many[klass] = klass.reflect_on_all_associations(:embeds_many).map { |i| i.name.to_s }
          else
            has_many[klass] = klass.reflect_on_all_associations(:has_many).map { |i| i.name.to_s }

            klass.reflect_on_all_associations(:has_and_belongs_to_many).inject(has_many[klass]) do |x, i|
              x << i.name.to_s
            end
          end
        end

        # Find the belongs_to associations which can be populated via  Model.belongs_to_name = OtherArModelObject
        if options[:reload] || belongs_to[klass].nil?
          belongs_to[klass] = klass.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }
        end

        # Find the has_one associations which can be populated via  Model.has_one_name = OtherArModelObject
        if options[:reload] || has_one[klass].nil?
          if Module.const_defined?(:Mongoid)
            has_one[klass] = klass.reflect_on_all_associations(:embeds_one).map { |i| i.name.to_s }
          else
            has_one[klass] = klass.reflect_on_all_associations(:has_one).map { |i| i.name.to_s }
          end
        end

        # Find the model's column associations which can be populated via xxxxxx= value
        # Note, not all reflections return method names in same style so we convert all to
        # the raw form i.e without the '='  for consistency
        if options[:reload] || assignments[klass].nil?
          build_assignments( klass, options[:instance_methods] )
        end
      end

      def self.clear
        belongs_to.clear
        has_many.clear
        assignments.clear
        column_types.clear
        has_one.clear
        catalogued.clear
      end

      # rubocop:disable Style/PredicateName

      def self.belongs_to
        @belongs_to ||= {}
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

      # N.B this return strings for consistency with other collections
      # Removes methods that start with '_'

      def self.setters( klass )

        @keep_only_pure_setters ||= Regexp.new(/^[a-zA-Z]\w+=/)

        setters = klass.instance_methods.grep(@keep_only_pure_setters).sort.collect( &:to_s )
        setters.uniq # TOFIX is this really required ?
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
        column_types[klass] ? column_types[klass][column] : []
      end

      def self.column_names( klass )
        Module.const_defined?(:Mongoid) ? klass.fields.keys : klass.column_names
      end

      # rubocop:enable Style/PredicateName

      class << self
        private

        def build_assignments(klass, include_instance_methods)
          begin
            assignments[klass] = Catalogue.column_names(klass)
          rescue => x
            raise DataShiftException, "Failed to process column_names for class #{klass} - #{x.message}"
          end

          # get into consistent format with other assignments names i.e remove the = for now
          assignments[klass] += setters(klass).map { |i| i.delete('=') } if include_instance_methods

          # Now remove all the associations
          assignments[klass] -= has_many[klass]   if has_many[klass]
          assignments[klass] -= belongs_to[klass] if belongs_to[klass]
          assignments[klass] -= has_one[klass]    if has_one[klass]

          # TODO: remove assignments with id
          # assignments => tax_id  but already in belongs_to => tax

          assignments[klass].uniq!

          assignments[klass].each do |assign|
            column_types[klass] ||= {}
            column_def = klass.columns.find { |col| col.name == assign }
            column_types[klass].merge!( assign => column_def) if column_def
          end unless (Module.const_defined?(:Mongoid))
        end

        def catalogued
          @catalogued ||= []
        end

        def register(klass)
          catalogued << klass
          catalogued.uniq!
        end
      end

    end

  end
end
