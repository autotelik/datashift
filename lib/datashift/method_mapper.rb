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
  
    
    # As well as just the column name, support embedding find operators for that column
    # in the heading .. i.e Column header => 'BlogPosts:user_id' 
    # ... association has many BlogPosts selected via find_by_user_id
    # 
    # in the heading .. i.e Column header => 'BlogPosts:user_name:John Smith' 
    # ... association has many BlogPosts selected via find_by_user_name("John Smith")
    #
    def self.column_delim
      @column_delim ||= ':'
      @column_delim
    end

    def self.set_column_delim(x)  @column_delim = x; end
    
  
    def initialize
      @method_details = []
    end

    # Build complete picture of the methods whose names listed in columns
    # Handles method names as defined by a user, from spreadsheets or file headers where the names
    # specified may not be exactly as required e.g handles capitalisation, white space, _ etc
    # 
    # The header can also contain the fields to use in lookups, separated with MethodMapper::column_delim
    # For example specify that lookups on has_one association called 'product', be performed using name'
    #   product:name
    #
    # The header can also contain a default value for the lookup field, again separated with MethodMapper::column_delim
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
        
        raw_col_name, lookup = raw_col_data.split(MethodMapper::column_delim)
         
        md = MethodDictionary::find_method_detail(klass, raw_col_name)
               
        if(md.nil?)          
          #puts "DEBUG: Check Forced\n #{forced}.include?(#{raw_col_name}) #{forced.include?(raw_col_name.downcase)}"
         
          if(options[:include_all] || forced.include?(raw_col_name.downcase))
            md = MethodDictionary::add(klass, raw_col_name)
          end
        end
        
        if(md)       
          md.name = raw_col_name
          md.column_index = col_index

          if(lookup)
            find_by, md.find_by_value = lookup.split(MethodMapper::column_delim)

            # Example :
            # User (klass) has_one project (operator) lookup by name  (find_by_operator) == 'My Best Project' (find_by_value)
            # User.project.where( :name => 'My Best Project')

            if(klass.respond_to?(md.operator) && klass.new.send(md.operator).respond_to?(find_by) )
              md.find_by_operator = find_by
              logger.debug("Complex Lookup specified for #{md.name};#{md.operator} : find_by operator #{md.find_by_operator} : find_by value #{md.find_by_value}")
            else
              logger.warn("Complex Lookup specified not found on operator or association #{klass}.#{md}")
            end

          end
        else
          # TODO populate unmapped with a real MethodDetail that is 'null' and create is_nil
          logger.warn("No operator or association found for Header #{raw_col_name}")
          @missing_methods << raw_col_name
        end
        
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