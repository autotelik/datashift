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

    def self.insistent_method_list
      @insistent_method_list ||= [:to_s, :to_i, :to_f, :to_b]
    end

    # When looking up an association, when no field provided, try each of these in turn till a match
    # i.e find_by_name, find_by_title, find_by_id
    def self.insistent_find_by_list
      @insistent_find_by_list ||= [:name, :title, :id]
    end


    attr_reader :value, :attribute_hash

    attr_accessor :previous_value, :original_data

    def initialize
      reset
    end

    # Main client hook

    def prepare_and_assign(context, record, data)
      prepare_data(context.method_binding, data)

      assign(context, record)
    end


    def reset
      @value, @previous_value, @original_data = nil, nil, nil
      @attribute_hash = {}
    end

    def has_value?
      !(value.nil?)
    end

    def self.attribute_hash_const_regexp
      @attribute_hash_const_regexp ||= Regexp.new( Delimiters::attribute_list_start + ".*" + Delimiters::attribute_list_end)
    end


    def default( method_binding )
      default = Transformer.factory.default(method_binding)

      if(default)
        @previous_value = value
        @value = default
      end
    end

    def substitute( method_binding )
      sub = Transformer.factory.substitution(method_binding)

      if(sub)
        @previous_value = value
        @value = previous_value.gsub(sub.pattern.to_s, sub.replacement.to_s)
      end
    end

    def override( method_binding )
      override = Transformer.factory.override(method_binding)

      if(override)
        @previous_value = value
        @value = override
      end
    end

    def prefix( method_binding )
      prefix = Transformer.factory.prefix(method_binding)

      if(prefix)
        @previous_value = value
        @value = prefix + @value
      end
    end

    def postfix( method_binding )
      postfix = Transformer.factory.postfix(method_binding)

      if(postfix)
        @previous_value = value
        @value = @value + postfix
      end
    end

    # Check supplied value, validate it, and if required :
    #   set to provided default value
    #   prepend any provided prefixes
    #   add any provided postfixes
    #
    # Rtns : tuple of [:value, :attribute_hash
    #
    def prepare_data(method_binding, data)

      raise NilDataSuppliedError.new("No method_binding supplied for prepare_data") unless(method_binding)

      @original_data = data

      begin

        if(data.is_a? ActiveRecord::Relation) # Rails 4 - query no longer returns an array
          @value = data.to_a

        elsif(data.class.ancestors.include?(ActiveRecord::Base) || data.is_a?(Array))
          @value = data

        elsif(data.is_a?(Spreadsheet::Formula))   # TOFIX jruby/apache poi equivalent ?
          @value = data.value

        else
          @value = data.to_s

          @attribute_hash = @value.slice!( Populator.attribute_hash_const_regexp )

          if(attribute_hash && !attribute_hash.empty?)
            #@value.chop!    # the slice seems to add an extra space/eol
            @attribute_hash = Populator::string_to_hash( attribute_hash )
            logger.info "Populator found attribute hash :[#{attribute_hash.inspect}]"
          else
            @attribute_hash = {}
          end
        end

        default( method_binding ) if(data.nil? || (data.respond_to?('empty?') && data.empty?))

        override( method_binding )

        substitute( method_binding )

        prefix( method_binding )

        postfix( method_binding )

      rescue => e
        logger.error(e.message)
        logger.error("Populator stacktrace: #{e.backtrace.first}")
        raise DataProcessingError.new("Populator failed to prepare data [#{value}] for #{method_binding.pp}")
      end

      return value, attribute_hash
    end


    def assign(context, record)

      method_binding = context.method_binding

      model_method = method_binding.model_method

      operator = model_method.operator

      if( model_method.operator_for(:belongs_to) )

        insistent_belongs_to(method_binding, record, value)

      elsif( model_method.operator_for(:has_many) )

        assign_has_many(context, record)

      elsif( model_method.operator_for(:has_one) )

        if(value.is_a?(model_method.klass))
          record.send(operator + '=', value)
        else
          logger.error("Cannot assign value [#{value.inspect}]")
          logger.error("Value was Type (#{value.class}) - Required Type for has_one #{operator} is [#{model_method.klass}]")
        end

      elsif( model_method.operator_for(:assignment) )

        if(model_method.col_type)
          logger.debug("Assignment via [#{operator}] to [#{value}] (CAST TYPE [#{ model_method.col_type.type_cast(value).inspect}])")

          record.send( operator + '=' , model_method.col_type.type_cast( value ) )
        else
          logger.debug("Brute force assignment of value  #{value} => [#{operator}]")
          # brute force case for assignments without a column type (which enables us to do correct type_cast)
          # so in this case, attempt straightforward assignment then if that fails, basic ops such as to_s, to_i, to_f etc
          insistent_assignment(record, value, operator)
        end

      else
        puts "WARNING: No assignment possible on #{record.inspect} using [#{operator}]"
        logger.error("WARNING: No assignment possible on #{record.inspect} using [#{operator}]")
      end
    end

    def insistent_assignment(record, value, operator)

      op = operator + '=' unless(operator.include?('='))

      begin
        record.send(op, value)
      rescue => e

        Populator::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
            if f == Populator::insistent_method_list.last
              logger.error(e.inspect)
              logger.error("Failed to assign [#{value}] via operator #{operator}")
              raise "Failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end

    # Attempt to find the associated object via id, name, title ....
    def insistent_belongs_to(method_binding, record, value )

      operator = method_binding.operator

      if( value.class == method_binding.klass)
        logger.info("Populator assigning #{value} to belongs_to association #{operator}")
        record.send(operator) << value
      else

        # TODO - DRY all this
        if(method_binding.find_by_operator)

          item = method_binding.klass.where(method_binding.find_by_operator => value).first_or_create

          if(item)
            logger.info("Populator assigning #{item.inspect} to belongs_to association #{operator}")
            record.send(operator + '=', item)
          else
            logger.error("Could not find or create [#{value}] for belongs_to association [#{operator}]")
            raise CouldNotAssignAssociation.new "Populator failed to assign [#{value}] to belongs_to association [#{operator}]"
          end

        else
          #try the default field names
          Populator::insistent_find_by_list.each do |x|
            begin

              next unless method_binding.klass.respond_to?("where")

              item = method_binding.klass.where(x => value).first_or_create

              if(item)
                logger.info("Populator assigning #{item.inspect} to belongs_to association #{operator}")
                record.send(operator + '=', item)
                break
              end
            rescue => e
              logger.error(e.inspect)
              logger.error("Failed attempting to find belongs_to for #{method_binding.pp}")
              if(x == Populator::insistent_method_list.last)
                raise CouldNotAssignAssociation.new "Populator failed to assign [#{value}] to belongs_to association [#{operator}]" unless value.nil?
              end
            end
          end
        end

      end
    end

    def assignment( operator, record, value )

      op = operator + '=' unless(operator.include?('='))

      begin
        record.send(op, value)
      rescue => e
        Populator::insistent_method_list.each do |f|
          begin
            record.send(op, value.send( f) )
            break
          rescue => e
            if f == Populator::insistent_method_list.last
              puts  "I'm sorry I have failed to assign [#{value}] to #{operator}"
              raise "I'm sorry I have failed to assign [#{value}] to #{operator}" unless value.nil?
            end
          end
        end
      end
    end


    def self.string_to_hash( str )
      str.to_hash_object
    end

    private

    attr_writer :value, :attribute_hash


    def assign_has_many(context, load_object)

      method_binding = context.method_binding

      # there are times when we need to save early, for example before assigning to
      # has_and_belongs_to associations which require the load_object has an id for the join table

      load_object.save_if_new

      collection = []
      columns = []

      if(value.is_a?(Array))

        value.each do |record|
          if(record.class.ancestors.include?(ActiveRecord::Base))
            collection << record
          else
            columns << record
          end
        end

      else
        # A single column can contain multiple lookup key:value definitions, delimited by special char
        # size:large | colour:red,green,blue => [where size: 'large'], [where colour: IN ['red,green,blue']
        columns = value.to_s.split( Delimiters::multi_assoc_delim )
      end

      operator = method_binding.operator

      columns.each do |col_str|

        # split into usable parts ; size:large or colour:red,green,blue
        field, find_by_values = Querying.where_field_and_values(method_binding, col_str )

        raise "Cannot perform DB find by #{field}. Expected format key:value" unless(field && find_by_values)

        found_values = []

        # we are looking up an association so need the Class of the Association
        klass = method_binding.model_method.operator_class

        raise CouldNotDeriveAssociationClass.new("Failed to find class for has_many Association : #{method_binding.pp}") unless(klass)

        logger.info("Running where clause on #{klass} : [#{field} IN #{find_by_values.inspect}]")

        find_by_values.each do |v|
          begin
            found_values << klass.where(field => v).first_or_create
          rescue => e
            logger.error(e.inspect)
            logger.error("Failed to find or create #{klass} where #{field} => #{v}")
            # TODO some way to define if this is a fatal error or not ?
          end
        end

        logger.info("Scan result #{found_values.inspect}")

        unless(find_by_values.size == found_values.size)
          found = found_values.collect {|f| f.send(field) }
          load_object.errors.add( operator, "Association with key(s) #{(find_by_values - found).inspect} NOT found")
          logger.error "Association [#{operator}] with key(s) #{(find_by_values - found).inspect} NOT found - Not added."
          next if(found_values.empty?)
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

  end
end