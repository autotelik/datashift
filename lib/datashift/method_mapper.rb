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
require 'method_detail'
require 'method_dictionary'

module DataShift

  class MethodMapper

    include DataShift::Logging
    
    attr_accessor :header_row, :headers
    attr_accessor :method_details, :missing_methods
  
    
    # As well as just the column name, support embedding find operators for that column
    # in the heading .. i.e Column header => 'BlogPosts:user_id' 
    # ... association has many BlogPosts selected via find_by_user_id
    # 
    def self.column_delim
      @column_delim ||= ':'
      @column_delim
    end

    def self.set_column_delim(x)  @column_delim = x; end
    
  
    def initialize
      @method_details = []
      @headers = []
    end

    # Build complete picture of the methods whose names listed in columns
    # Handles method names as defined by a user, from spreadsheets or file headers where the names
    # specified may not be exactly as required e.g handles capitalisation, white space, _ etc
    # Returns: Array of matching method_details
    #
    def map_inbound_to_methods( klass, columns )
      
      @method_details, @missing_methods = [], []
    
      columns.each do |name|
        if(name.nil? or name.empty?)
          logger.warn("Column list contains empty or null columns") 
          next
        end
        
        x, lookup = name.split(MethodMapper::column_delim) 
        md = MethodDictionary::find_method_detail( klass, x )
        
        # TODO be nice if we could cheeck that the assoc on klass responds to the specified
        # lookup key now (nice n early)
        # active_record_helper = "find_by_#{lookup}"
        
        md.find_by_operator = lookup if(lookup) # TODO and klass.x.respond_to?(active_record_helper))
        md ? @method_details << md : @missing_methods << x
      end
      #@method_details.compact!  .. currently we may need to map via the index on @method_details so don't remove nils for now
      @method_details
    end

    # The raw client supplied names
    def method_names()
      @method_details.collect( &:name )
    end

    # The true operator names discovered from model
    def operator_names()
      @method_details.collect( &:operator )
    end

    # Returns true if discovered methods contain every operator in mandatory_list
    def contains_mandatory?( mandatory_list )
      [ [*mandatory_list] - operator_names].flatten.empty?
    end

    def missing_mandatory( mandatory_list )
      [ [*mandatory_list] - operator_names].flatten
    end

  end

end