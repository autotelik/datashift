# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     March 2016
# License::   MIT
#
# Details::   Assign a value to a has_many active record association.
#
#             Enables users to assign values to AR object, without knowing much about that receiving object.
#
module DataShift

  module Populators

    class HasMany

      include DataShift::Logging
      extend DataShift::Logging

      include DataShift::Delimiters
      extend DataShift::Delimiters

      # A single column can contain multiple lookup key:value definitions.
      # These are delimited by special char defined in Delimiters
      #
      # For example:
      #
      #   size:large | colour:red,green,blue |
      #
      # Should result in
      #
      #       => [where size: 'large'], [where colour: IN ['red,green,blue']
      #
      def self.split_into_multiple_lookup(value)
        value.to_s.split( multi_assoc_delim )
      end

      # def self.call(record, value, operator)

      def self.call(load_object, value, method_binding)

        # there are times when we need to save early, for example before assigning to
        # has_and_belongs_to associations which require the load_object has an id for the join table

        load_object.save_if_new

        collection = []
        columns = []

        if value.is_a?(Array)

          value.each do |record|
            if record.class.ancestors.include?(ActiveRecord::Base)
              collection << record
            else
              columns << record
            end
          end

        else
          columns = split_into_multiple_lookup(value)
        end

        operator = method_binding.operator

        columns.each do |col_str|
          # split into usable parts ; size:large or colour:red,green,blue
          field, find_by_values = Querying.where_field_and_values(method_binding, col_str )

          raise "Cannot perform DB find by #{field}. Expected format key:value" unless field && find_by_values

          found_values = []

          # we are looking up an association so need the Class of the Association
          klass = method_binding.model_method.operator_class

          raise CouldNotDeriveAssociationClass, "Failed to find class for has_many Association : #{method_binding.pp}" unless klass

          logger.info("Running where clause on #{klass} : [#{field} IN #{find_by_values.inspect}]")

          find_by_values.each do |v|
            begin
              found_values << klass.where(field => v).first_or_create
            rescue => e
              logger.error(e.inspect)
              logger.error("Failed to find or create #{klass} where #{field} => #{v}")
              # TODO: some way to define if this is a fatal error or not ?
            end
          end

          logger.info("Scan result #{found_values.inspect}")

          unless find_by_values.size == found_values.size
            found = found_values.collect { |f| f.send(field) }
            load_object.errors.add( operator, "Association with key(s) #{(find_by_values - found).inspect} NOT found")
            logger.error "Association [#{operator}] with key(s) #{(find_by_values - found).inspect} NOT found - Not added."
            next if found_values.empty?
          end

          logger.info("Assigning to has_many [#{operator}] : #{found_values.inspect} (#{found_values.class})")

          begin
            load_object.send(operator) << found_values
          rescue => e
            logger.error e.inspect
            logger.error "Cannot assign #{found_values.inspect} to has_many [#{operator}] "
          end

          logger.info("Assignment to has_many [#{operator}] COMPLETE)")
        end
      end

    end
  end
end
