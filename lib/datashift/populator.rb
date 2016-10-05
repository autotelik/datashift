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

      connection_adapter_column = method_binding.model_method.connection_adapter_column


      raise NilDataSuppliedError, 'No method_binding supplied for prepare_data' unless method_binding

      @original_data = data

      begin

        if(data.is_a?(ActiveRecord::Relation)) # Rails 4 - query no longer returns an array
          @value = data.to_a

        elsif(data.class.ancestors.include?(ActiveRecord::Base) || data.is_a?(Array))
          @value = data

        elsif(!DataShift::Guards.jruby? &&
          (data.is_a?(Spreadsheet::Formula) || data.class.ancestors.include?(Spreadsheet::Formula)) )

          @value = data.value  # TOFIX jruby/apache poi equivalent ?

        elsif(connection_adapter_column && connection_adapter_column.cast_type.is_a?(ActiveRecord::Type::Boolean))

          # DEPRECATION WARNING: You attempted to assign a value which is not explicitly `true` or `false` ("0.00")
          # to a boolean column. Currently this value casts to `false`.
          # This will change to match Ruby's semantics, and will cast to `true` in Rails 5.
          # If you would like to maintain the current behavior, you should explicitly handle the values you would like cast to `false`.

          @value = if(data.in? [true, false])
                     data
                   else
                     (data.to_s.downcase == "true" || data.to_s.to_i == 1) ? true : false
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
      elsif  model_method.operator_for(:has_many)
        assign_has_many(method_binding, record)
      elsif  model_method.operator_for(:has_one)

        if value.is_a?(model_method.klass)
          record.send(operator + '=', value)
        else
          logger.error("Cannot assign value [#{value.inspect}]")
          logger.error("Value was Type (#{value.class}) - Required Type for has_one #{operator} is [#{klass}]")
        end

      elsif  model_method.operator_for(:assignment)

        if model_method.connection_adapter_column

          return if check_process_enum(record, model_method )  # TOFIX .. enum section probably belongs in prepare_data

          assignment(record, value, model_method)

        else
          logger.debug("Brute force assignment of value  #{value} => [#{operator}]")
          # brute force case for assignments without a column type (which enables us to do correct type_cast)
          # so in this case, attempt straightforward assignment then if that fails, basic ops such as to_s, to_i, to_f etc
          insistent_assignment(record, value, operator)
        end

      elsif model_method.operator_for(:method)
        logger.debug("Method delegation assignment of value  #{value} => [#{operator}]")
        insistent_assignment(record, value, operator)

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

    def insistent_assignment(record, value, operator)

      op = operator + '=' unless operator.include?('=')

      # TODO: - fix this crap - perhaps recursion ??
      begin
        record.send(op, value)
      rescue
        begin
          op = operator.downcase
          op += '=' unless operator.include?('=')

          record.send(op, value)

        rescue => e

          Populator.insistent_method_list.each do |f|
            begin
              record.send(op, value.send(f) )
              break
            rescue => e
              if f == Populator.insistent_method_list.last
                logger.error(e.inspect)
                logger.error("Failed to assign [#{value}] via operator #{operator}")
                raise DataProcessingError, "Failed to assign [#{value}] to #{operator}" unless value.nil?
              end
            end
          end
        end
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
              raise CouldNotAssignAssociation,
                    "Populator failed to assign [#{value}] to belongs_to association [#{operator}]" unless value.nil?
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

    # A single column can contain multiple lookup key:value definitions.
    # These are delimited by special char defined in Delimiters
    #
    # For example:
    #
    #   size:large | colour:red,green,blue |
    #
    def split_multi_assoc_value
      value.to_s.split( multi_assoc_delim )
    end

    def assign_has_many(method_binding, load_object)

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
        # A single column can contain multiple lookup key:value definitions, delimited by special char
        # size:large | colour:red,green,blue => [where size: 'large'], [where colour: IN ['red,green,blue']
        columns = split_multi_assoc_value
      end

      operator = method_binding.operator

      columns.each do |col_str|
        # split into usable parts ; size:large or colour:red,green,blue
        field, find_by_values = Querying.where_field_and_values(method_binding, col_str )

        raise "Cannot perform DB find by #{field}. Expected format key:value" unless field && find_by_values

        found_values = []

        # we are looking up an association so need the Class of the Association
        klass = method_binding.model_method.operator_class

        raise CouldNotDeriveAssociationClass,
              "Failed to find class for has_many Association : #{method_binding.pp}" unless klass

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
      end # END HAS_MANY
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
