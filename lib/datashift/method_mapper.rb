# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   A base class that stores details of all possible associations on AR classes and,
#             given user supplied class and name, attempts to find correct attribute/association.
#
#             Derived classes define where the user supplied list of names originates from.
#
#             Example usage, load from a spreadsheet where the column names are only
#             an approximation of the actual associations. Given a column heading of
#             'Product Properties' on class Product,  find_method_detail() would search AR model,
#             and return details of real has_many association 'product_properties'.
#
#             This real association can then be used to send spreadsheet row data to the AR object.
#             
module DataShift

  class MethodMapper

    include DataShift::Logging
    
    attr_accessor :method_details, :missing_methods
  
    def initialize
      @method_details = []
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
    def map_inbound_headers_to_methods( klass, columns, options = {} )
      
      # If klass not in MethodDictionary yet, add to dictionary all possible operators on klass
      # which can be used to map headers and populate an object of type klass
      unless(MethodDictionary::for?(klass))
        DataShift::MethodDictionary.find_operators(klass)
        
        DataShift::MethodDictionary.build_method_details(klass)
      end 
      
      mgr = DataShift::MethodDictionary.method_details_mgrs[klass]
       
      forced = [*options[:force_inclusion]].compact.collect { |f| f.to_s.downcase }
      
      @method_details, @missing_methods = [], []
    
      columns.each_with_index do |col_data, col_index|

        raw_col_data = col_data.to_s
        
        if(raw_col_data.nil? or raw_col_data.empty?)
          logger.warn("Column list contains empty or null column at index #{col_index}") 
          @method_details << nil
          next
        end
        
        raw_col_name, lookup = raw_col_data.split(Delimiters::column_delim)
         
        md = MethodDictionary::find_method_detail(klass, raw_col_name)

        if(md.nil?)
          if(options[:include_all] || forced.include?(raw_col_name.downcase))
            logger.debug("Operator #{raw_col_name} not found but forced inclusion operative")
            md = MethodDictionary::add(klass, raw_col_name)
          end
        end
        
        if(md)       
          md.name = raw_col_name
          md.column_index = col_index

          if(lookup)
            logger.info("Lookup data [#{lookup}] - specified for association #{md.operator}")

            md.find_by_operator, md.find_by_value = lookup.split(Delimiters::name_value_delim)

            # Example :
            # Project:name:My Best Project
            #   User (klass) has_one project (operator) lookup by name  (find_by_operator) == 'My Best Project' (find_by_value)
            #   User.project.where( :name => 'My Best Project')

            # check the finder method name is a valid field on the actual association class

            if(klass.reflect_on_association(md.operator) &&
               klass.reflect_on_association(md.operator).klass.new.respond_to?(md.find_by_operator))
              logger.info("Complex Lookup specified for [#{md.operator}] : on field [#{md.find_by_operator}] (optional value [#{md.find_by_value}])")
            else
              logger.warn("Find by operator [#{md.find_by_operator}] Not Found on association [#{md.operator}] on Class #{klass.name} (#{md.inspect})")
              logger.warn("Check column (#{md.column_index}) heading - e.g association field names are case sensitive")
              md.find_by_operator, md.find_by_value = nil, nil
            end
          end
        else
          # TODO populate unmapped with a real MethodDetail that is 'null' and create is_nil
          logger.warn("No operator or association found for Header #{raw_col_name}")
          @missing_methods << raw_col_name
        end

        logger.debug("Column [#{col_data}] (#{col_index}) - mapped to :\n#{md.inspect}")

        @method_details << md
        
      end
     
      @method_details
    end

    
    # TODO populate unmapped with a real MethodDetail that is 'null' and create is_nil
    # 
    # The raw client supplied names
    def method_names()
      @method_details.compact.collect( &:name )
    end

    # The true operator names discovered from model
    def operator_names()
      @method_details.compact.collect( &:operator )
    end

    
    # Returns true if discovered methods contain every operator in mandatory_list
    def contains_mandatory?( mandatory_list )
      a = [*mandatory_list].collect { |f| f.downcase }
      puts a.inspect
      b = operator_names.collect { |f| f.downcase }
      puts b.inspect
      (a - b).empty?
    end

    def missing_mandatory( mandatory_list )
      [ [*mandatory_list] - operator_names].flatten
    end

  end

end