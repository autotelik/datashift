# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Binds incoming string headers to domain model's
#             attribute/association.
#
#             Example usage, load from a spreadsheet where the column names are only
#             an approximation of the actual associations. Given a column heading of
#             'Product Properties' on class Product,  find_method_detail() would search AR model,
#             and return details of real has_many association 'product_properties'.
#
#             This real association can then be used to send spreadsheet row data to the AR object.
#
module DataShift

  class Binder

    include DataShift::Logging

    attr_reader :mapped_class

    attr_accessor :bindings, :missing_bindings

    def initialize
      reset
    end

    def reset
      @bindings = []
      @missing_bindings = []
    end

    def missing_bindings?
      !missing_bindings.empty?
    end

    def headers_missing_bindings
      missing_bindings.collect &:inbound_name
    end

    def indexes_missing_bindings
      missing_bindings.collect &:inbound_index
    end

    # Build complete picture of the methods whose names listed in columns
    # Handles method names as defined by a user, from spreadsheets or file headers where the names
    # specified may not be exactly as required e.g handles capitalisation, white space, _ etc
    #
    # The header can also contain the fields to use in lookups, separated with Delimiters ::column_delim
    # For example specify that lookups on has_one association called 'product', be performed using name'
    #   product:name
    #
    # The header can also contain a default value for the lookup field, again separated with Delimiters ::column_delim
    #
    # For example specify lookups on assoc called 'user', be performed using 'email' == 'test@blah.com'
    #
    #   user:email:test@blah.com
    #
    # Returns: Array of matching method_details, including nils for non matched items
    #
    # N.B Columns that could not be mapped are left in the array as NIL
    #
    # This is to support clients that need to map via the index on @method_details
    #
    # Other callers can simply call compact on the results if the index not important.
    #
    # The MethodDetails instance will contain a pointer to the column index from which it was mapped.
    #
    # Options:
    #
    #   [:force_inclusion]  : List of columns that do not map to any operator but should be included in processing.
    #
    #       This provides the opportunity for loaders to provide specific methods to handle these fields
    #       when no direct operator is available on the model or it's associations
    #
    #   [:include_all]      : Include all headers in processing - takes precedence of :force_inclusion
    #
    #   [:model_classes]    : Also ensure these classes are included in ModelMethods Dictionary

    def map_inbound_headers( klass, columns, options = {} )

      @mapped_class = klass

      # If klass not in Dictionary yet, add to dictionary all possible operators on klass
      # which can be used to map headers and populate an object of type klass
      model_method_mgr = ModelMethods::Manager.catalog_class(klass)

      [*options[:model_classes]].each do |c|
        ModelMethods::Manager.catalog_class(c)
      end if(options[:model_classes])

      forced = [*options[:force_inclusion]].compact.collect { |f| f.to_s.downcase }

      reset

      [*columns].each_with_index do |col_data, col_index|
        raw_col_data = col_data.to_s

        if(raw_col_data.nil? || raw_col_data.empty?)
          logger.warn("Column list contains empty or null column at index #{col_index}")
          bindings << NoMethodBinding.new(raw_col_data, col_index)
          next
        end

        raw_col_name, where_field, where_value, *data = raw_col_data.split(Delimiters.column_delim)

        # Find the domain model method details
        model_method = model_method_mgr.search(raw_col_name)

        # if not found via raw name, try various alternatives
        unless(model_method)
          Binder.substitutions(raw_col_name).each do |n|
            model_method = model_method_mgr.search(n)
            break if(model_method)
          end
        end

        model_method = if(options[:include_all] || forced.include?(raw_col_name.downcase))
                         logger.debug("Operator #{raw_col_name} not found but forced inclusion set - adding as :method")
                         model_method_mgr.insert(raw_col_name, :method)
                        end if(model_method.nil?)

        if(model_method)

          binding = MethodBinding.new(raw_col_name, col_index, model_method)

          # we slurped up all possible data in split, turn it back into original string
          binding.add_column_data(data.join(Delimiters.column_delim))

          if(where_field)
            logger.info("Lookup query field [#{where_field}] - specified for association #{model_method.operator}")

            begin
              binding.add_lookup(model_method, where_field, where_value)
            rescue => x
              add_missing(raw_col_data, col_index, "Field [#{where_field}] Not Found for [#{raw_col_name}] (#{model_method.operator})")
              next
            end

          end

          logger.debug("Column [#{col_data}] (#{col_index}) - mapped to :\n#{model_method.pp}")

          bindings << binding

        else
          logger.debug("No operator or association found for Header [#{raw_col_name}]")

          add_missing(raw_col_data, col_index, "No operator or association found for Header [#{raw_col_name}]")
        end
      end

      bindings
    end

    # Essentially we map any string collection of field names, not just headers from files
    alias_method :map_inbound_fields, :map_inbound_headers

    def add_missing(col_data, col_index, reason)
      logger.warn(reason)

      missing = NoMethodBinding.new(col_data, col_index, reason: reason)

      missing_bindings << missing
      bindings << missing
    end

    # TODO: - check out regexp to do this work better plus Inflections ??
    # Want to be able to handle any of ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand" etc]
    def self.substitutions(external_name)
      name = external_name.to_s

      [
        name.downcase,
        name.tableize,
        name.tr(' ', '_'),
        name.tr(' ', '_').downcase,
        name.gsub(/(\s+)/, '_').downcase,
        name.delete(' '),
        name.delete(' ').downcase,
        name.tr(' ', '_').underscore
      ]
    end

    # The raw client supplied names
    def method_names
      bindings.collect( &:inbound_name )
    end

    # The true operator names discovered from model
    def operator_names
      bindings.collect( &:operator )
    end

  end

end
