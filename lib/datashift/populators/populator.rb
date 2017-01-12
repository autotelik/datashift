# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     March 2012
# License::   MIT
#
# Details::   The default Populator class for assigning data to models
#
#             Provides individual population methods on an AR model.
#
#             Enables users to assign values to AR object, without knowing much about that receiving object.
#
require_relative 'has_many'
require_relative 'insistent_assignment'

module DataShift

  class Populator

    include DataShift::Logging
    extend DataShift::Logging

    include DataShift::Delimiters
    extend DataShift::Delimiters

    def self.insistent_method_list
      @insistent_method_list ||= [:to_s, :downcase, :to_i, :to_f, :to_b]
    end

    # When looking up an association, when no field provided, try each of these in turn till a match
    # i.e find_by_name, find_by_title, find_by_id
    def self.insistent_find_by_list
      @insistent_find_by_list ||= [:name, :title, :id]
    end

    attr_reader :value, :attribute_hash

    attr_accessor :previous_value, :original_data

    def initialize(transformer = nil)
      # reset
      @transformer = transformer || Transformation.factory

      @attribute_hash = {}
    end

    # Main client hooks :

    # Prepare the data to be populated, then assign to the Db record

    def prepare_and_assign(context, record, data)
      prepare_and_assign_method_binding(context.method_binding, record, data)
    end

    # This is the most pertinent hook for derived Processors, where you can provide custom
    # population messages for specific Method bindings

    def prepare_and_assign_method_binding(method_binding, record, data)
      prepare_data(method_binding, data)

      assign(method_binding, record)
    end

    def reset
      @value = nil
      @previous_value = nil
      @original_data = nil
      @attribute_hash = {}
    end

    def value?
      !value.nil?
    end

    def self.attribute_hash_const_regexp
      @attribute_hash_const_regexp ||= Regexp.new( attribute_list_start + '.*' + attribute_list_end)
    end

    # Check supplied value, validate it, and if required :
    #   set to provided default value
    #   prepend any provided prefixes
    #   add any provided postfixes
    #
    # Rtns : tuple of [:value, :attribute_hash]
    #

    def prepare_data(method_binding, data)

      raise NilDataSuppliedError, 'No method_binding supplied for prepare_data' unless method_binding

      @original_data = data

      begin
        model_method = method_binding.model_method

        if(data.is_a?(ActiveRecord::Relation)) # Rails 4 - query no longer returns an array
          @value = data.to_a

        elsif(data.class.ancestors.include?(ActiveRecord::Base) || data.is_a?(Array))
          @value = data

        elsif(!DataShift::Guards.jruby? &&
          (data.is_a?(Spreadsheet::Formula) || data.class.ancestors.include?(Spreadsheet::Formula)) )

          @value = data.value # TOFIX jruby/apache poi equivalent ?

        elsif( model_method.can_cast? && model_method.cast_type.is_a?(ActiveRecord::Type::Boolean))

          # DEPRECATION WARNING: You attempted to assign a value which is not explicitly `true` or `false` ("0.00")
          # to a boolean column. Currently this value casts to `false`.
          # This will change to match Ruby's semantics, and will cast to `true` in Rails 5.
          # If you would like to maintain the current behavior, you should explicitly handle the values you would like cast to `false`.

          @value = if(data.in? [true, false])
                     data
                   else
                     data.to_s.casecmp('true').zero? || data.to_s.to_i == 1 ? true : false
                   end
        else
          @value = data.to_s

          @attribute_hash = @value.slice!( Populator.attribute_hash_const_regexp )

          if attribute_hash && !attribute_hash.empty?
            @attribute_hash = Populator.string_to_hash( attribute_hash )
            logger.info "Populator found attribute hash :[#{attribute_hash.inspect}]"
          else
            @attribute_hash = {}
          end
        end

        run_transforms(method_binding)

      rescue => e
        logger.error(e.message)
        logger.error("Populator stacktrace: #{e.backtrace.first}")
        raise DataProcessingError, "Populator failed to prepare data [#{value}] for #{method_binding.pp}"
      end

      [value, attribute_hash]
    end

    def assign(method_binding, record)

      model_method = method_binding.model_method

      operator = model_method.operator

      klass = model_method.klass

      if model_method.operator_for(:belongs_to)
        insistent_belongs_to(method_binding, record, value)

      elsif(model_method.operator_for(:has_many))

        DataShift::Populators::HasMany.call(record, value, method_binding)

      elsif model_method.operator_for(:has_one)

        if value.is_a?(model_method.klass)
          record.send(operator + '=', value)
        else
          logger.error("Cannot assign value [#{value.inspect}]")
          logger.error("Value was Type (#{value.class}) - Required Type for has_one #{operator} is [#{klass}]")
        end

      elsif model_method.operator_for(:assignment)

        if model_method.connection_adapter_column

          return if check_process_enum(record, model_method ) # TOFIX .. enum section probably belongs in prepare_data

          assignment(record, value, model_method)

        else
          DataShift::Populators::InsistentAssignment.call(record, value, operator)

          logger.debug("Assigned #{value} => [#{operator}]")
        end

      elsif model_method.operator_for(:method)

        begin
          params_num = record.method(operator.to_sym).arity

          # think this should be == 0 but seen situations where -1 returned even though method accepts ZERO params
          if(params_num < 1)
            logger.debug("Calling Custom Method (no value) [#{operator}]")
            record.send(operator)
          elsif(value)
            logger.debug("Custom Method assignment of value  #{value} => [#{operator}]")
            record.send(operator, value)
          end
        rescue => e
          logger.error e.backtrace.first
          raise DataProcessingError, "Method [#{operator}] could not process #{value} - #{e.inspect}"
        end

      else
        logger.warn("Cannot assign via [#{operator}] to #{record.inspect} ")
      end

    end

    def assignment(record, value, model_method)

      operator = model_method.operator
      connection_adapter_column = model_method.connection_adapter_column

      begin
        if(connection_adapter_column.respond_to? :type_cast)
          logger.debug("Assignment via [#{operator}] to [#{value}] (CAST TYPE [#{model_method.connection_adapter_column.type_cast(value).inspect}])")

          record.send( operator + '=', model_method.connection_adapter_column.type_cast( value ) )

        else
          logger.debug("Assignment via [#{operator}] to [#{value}] (NO CAST)")

          # Good guide on diff ways to set attributes
          #   http://www.davidverhasselt.com/set-attributes-in-activerecord/
          if(DataShift::Configuration.call.update_and_validate)
            record.update( operator => value)
          else
            record.send( operator + '=', value)
          end
        end
      rescue => e
        logger.error e.backtrace.first
        logger.error("Assignment failed #{e.inspect}")
        raise DataProcessingError, "Failed to set [#{value}] via [#{operator}] due to ERROR : #{e.message}"
      end
    end

    # Attempt to find the associated object via id, name, title ....
    def insistent_belongs_to(method_binding, record, value )

      operator = method_binding.operator

      klass = method_binding.model_method.operator_class

      if value.class == klass
        logger.info("Populator assigning #{value} to belongs_to association #{operator}")
        record.send(operator) << value
      else

        unless method_binding.klass.respond_to?('where')
          raise CouldNotAssignAssociation, "Populator failed to assign [#{value}] to belongs_to [#{operator}]"
        end

        # Try the default field names

        # TODO: - add find by operators from headers or configuration to  insistent_find_by_list
        Populator.insistent_find_by_list.each do |find_by|
          begin

            item = klass.where(find_by => value).first_or_create

            next unless item

            logger.info("Populator assigning #{item.inspect} to belongs_to association #{operator}")
            record.send(operator + '=', item)
            break

          rescue => e
            logger.error(e.inspect)
            logger.error("Failed attempting to find belongs_to for #{method_binding.pp}")
            if find_by == Populator.insistent_method_list.last
              unless value.nil?
                raise CouldNotAssignAssociation,
                      "Populator failed to assign [#{value}] to belongs_to association [#{operator}]"
              end
            end
          end
        end

      end
    end

    def check_process_enum(record, model_method)

      klass = model_method.klass
      operator = model_method.operator

      if klass.respond_to?(operator.pluralize)

        enums = klass.send(operator.pluralize)

        logger.debug("Checking for enum - #{enums.inspect} - #{value.parameterize.underscore}" )

        if enums.is_a?(Hash) && enums.keys.include?(value.parameterize.underscore)
          # ENUM
          logger.debug("[#{operator}] Appears to be an ENUM - setting to [#{value}])")

          # TODO: - now we know this column is an enum set operator type to :enum to save this check in future
          # probably requires changes above to just assign enum directly without this check
          model_method.operator_for(:assignment)

          record.send( operator + '=', value.parameterize.underscore)
          return true
        end
      end
    end

    def self.string_to_hash( str )
      str.to_hash_object
    end

    private

    attr_writer :value, :attribute_hash

    # TOFIX - Does not belong in this class
    def run_transforms(method_binding)
      default( method_binding ) if value.blank?

      override( method_binding )

      substitute( method_binding )

      prefix( method_binding )

      postfix( method_binding )

      # TODO: - enable clients to register their own transformation methods and call them here
    end

    # Transformations

    def default( method_binding )
      default = Transformation.factory.default(method_binding)

      return unless default

      @previous_value = value
      @value = default
    end

    # Checks Transformation for a substitution for column defined in method_binding
    def substitute( method_binding )
      sub = Transformation.factory.substitution(method_binding)

      return unless sub
      @previous_value = value
      @value = previous_value.gsub(sub.pattern.to_s, sub.replacement.to_s)
    end

    def override( method_binding )
      override = Transformation.factory.override(method_binding)

      return unless override
      @previous_value = value
      @value = override
    end

    def prefix( method_binding )
      prefix = Transformation.factory.prefix(method_binding)

      return unless prefix
      @previous_value = value
      @value = prefix + @value
    end

    def postfix( method_binding )
      postfix = Transformation.factory.postfix(method_binding)

      return unless postfix
      @previous_value = value
      @value += postfix
    end

  end
end
