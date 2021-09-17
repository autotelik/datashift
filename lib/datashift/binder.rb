# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Binds incoming string headers to domain model's attribute/association.
#
#             So a binding is a mapping between an Inbound Column and a ModelMethod
#
#             Example usage, load from a spreadsheet where the column names are only
#             an approximation of the actual associations.
#
#             Given a column heading of 'Product Properties' on class Product,  map_inbound_headers would search
#             the Product AR model, for a matching method or association, in this case  would
#             bind this column, 'Product Properties', to the has_many association 'product_properties'.
#
#             This binding can be used to send spreadsheet row data to populate the product_properties on a product
#
#             Sometimes there may be no automatic binding available, but you may want to supply a custom method to process
#             that column, in which case the following options may come into play
#
#             You can specify a list of columns to be bound even if no mapping is found using
#               DataShift::Configuration.force_inclusion_of_columns = []
#
#             You can force inclusion of all columns despite whether mapping found or not using
#               DataShift::Configuration.include_all = true
#
#
module DataShift

  class Binder

    include DataShift::Logging

    include DataShift::Delimiters
    extend DataShift::Delimiters

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
      missing_bindings.collect(&:source)
    end

    def indexes_missing_bindings
      missing_bindings.collect(&:index)
    end

    def forced_inclusion_columns
      [*DataShift::Configuration.call.force_inclusion_of_columns]
    end

    def forced
      forced_inclusion_columns.compact.collect { |f| f.to_s.downcase }
    end

    def forced?(column_name)
      (forced & Binder.substitutions(column_name)).present?
    end

    def include_all?
      DataShift::Configuration.call.include_all_columns == true
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
    def map_inbound_headers(klass, columns)

      # If klass not in Dictionary yet, add to dictionary all possible operators on klass
      # which can be used to map headers and populate an object of type klass
      model_methods_collection = ModelMethods::Manager.catalog_class(klass)

      bound = bindings.map(&:source)

      [*columns].each_with_index do |col_data, col_index|
        raw_col_data = col_data.to_s.strip

        if raw_col_data.nil? || raw_col_data.empty?
          logger.warn("Column list contains empty or null header at index #{col_index}")
          bindings << NoMethodBinding.new(raw_col_data, idx: col_index)
          next
        end

        # Header DSL Name::Where::Value:Misc
        # For example :
        #     product_properties:name:test_pp_003
        #       => ProductProperty.where()name: "test_pp_003")
        #
        raw_col_name, where_field, where_value, *data = raw_col_data.split(column_delim).map(&:strip)

        # Config loaded details trump internal mappings. User may not bother setting index of the column
        # in config, so attempt now to match it to actual header
        if bound.include?(raw_col_name)
          external = bindings.find { |b| b.source == raw_col_name }
          external.index = col_index if(external && external.index.nil?)
          next
        end

        # Find the domain model method details
        model_method = model_methods_collection.search(raw_col_name)

        # No such column, so check config
        #
        #   Forced inclusion for example for delegated methods that do not show up in reflection.
        #
        # Add as operator type :assignment
        #
        if( model_method.nil? && (include_all? || forced?(raw_col_name)) )
          logger.debug("Operator #{raw_col_name} not found but forced inclusion set - adding as :assignment")
          model_method = model_methods_collection.insert(raw_col_name, :assignment)
        end

        unless model_method
          Binder.substitutions(raw_col_name).each do |n|
            model_method = model_methods_collection.search(n)
            break if model_method
          end
        end

        if(model_method)

          binding = MethodBinding.new(raw_col_name, model_method, idx: col_index)

          # we slurped up all possible data in split, turn it back into original string
          binding.add_column_data(data.join(column_delim))

          if where_field
            logger.info("Lookup query field [#{where_field}] - specified for association #{model_method.operator}")

            begin
              binding.add_lookup(model_method, where_field, where_value)
            rescue StandardError => e
              logger.error(e.message)
              add_missing(raw_col_data, col_index, "Field [#{where_field}] Not Found for [#{raw_col_name}] (#{model_method.operator})")
              next
            end

          end

          logger.debug("Column [#{raw_col_data}] (#{col_index}) - mapped to :\n#{model_method.pp}")

          bindings << binding
        else
          add_missing(raw_col_data, col_index, "No operator or association found for Header [#{raw_col_name}]")
        end
      end
      bindings.sort_by!(&:index)
      bindings
    end

    def add_bindings_from_nodes( nodes )
      nodes.each { |n| bindings << n.method_binding unless n.is_a?(NoMethodBinding) }
      bindings.sort_by!(&:index)
    end

    # Essentially we map any string collection of field names, not just headers from files
    alias map_inbound_fields map_inbound_headers

    def add_missing(col_data, col_index, reason)
      logger.warn(reason)

      missing = NoMethodBinding.new(col_data, reason: reason, idx: col_index)

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
      ].uniq
    end

    # The raw client supplied names
    def method_names
      bindings.collect( &:source )
    end

    # The true operator names discovered from model
    def operator_names
      bindings.collect( &:operator )
    end

    # Find a binding, matches raw client supplied names e.g header and has a valid index
    def find_for_source( name )
      bindings.find { |b| b.source == name && b.index }
    end

  end

end
