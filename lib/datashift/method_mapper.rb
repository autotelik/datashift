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

module DataShift

  class MethodMapper

    attr_accessor :header_row, :headers
    attr_accessor :method_details, :missing_methods
  
    @@has_many     = Hash.new
    @@belongs_to   = Hash.new
    @@assignments  = Hash.new
    @@column_types = Hash.new

    def initialize
      @method_details = []
      @headers = []
    end

    # Build complete picture of the methods whose names listed in method_list
    # Handles method names as defined by a user or in file headers where names may
    # not be exactly as required e.g handles capitalisation, white space, _ etc
    # Returns: Array of matching method_details
    #
    def populate_methods( klass, method_list )
      @method_details, @missing_methods = [], []
    
      method_list.each do |x|
        md = MethodMapper::find_method_detail( klass, x )
        md ? @method_details << md : @missing_methods << x
      end
      #@method_details.compact!  .. currently we may neeed to map via the index on @method_details so don't remove nils for now
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

    # Create picture of the operators for assignment available on an AR model,
    # including via associations (which provide both << and = )
    # Options:
    # :reload => clear caches and reperform  lookup
    # :instance_methods => if true include instance method type assignment operators as well as model's pure columns
    #
    def self.find_operators(klass, options = {} )

      # Find the has_many associations which can be populated via <<
      if( options[:reload] || @@has_many[klass].nil? )
        @@has_many[klass] = klass.reflect_on_all_associations(:has_many).map { |i| i.name.to_s }
        klass.reflect_on_all_associations(:has_and_belongs_to_many).inject(@@has_many[klass]) { |x,i| x << i.name.to_s }
      end
      # puts "DEBUG: Has Many Associations:", @@has_many[klass].inspect

      # Find the belongs_to associations which can be populated via  Model.belongs_to_name = OtherArModelObject
      if( options[:reload] || @@belongs_to[klass].nil? )
        @@belongs_to[klass] = klass.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }
      end

      #puts "Belongs To Associations:", @@belongs_to[klass].inspect

      # Find the has_one associations which can be populated via  Model.has_one_name = OtherArModelObject
      if( options[:reload] || self.has_one[klass].nil? )
        self.has_one[klass] = klass.reflect_on_all_associations(:has_one).map { |i| i.name.to_s }
      end

      #puts "has_one Associations:", self.has_one[klass].inspect

      # Find the model's column associations which can be populated via xxxxxx= value
      # Note, not all reflections return method names in same style so we convert all to
      # the raw form i.e without the '='  for consistency 
      if( options[:reload] || @@assignments[klass].nil? )

        @@assignments[klass] = klass.column_names
           
        if(options[:instance_methods] == true)
          setters = klass.instance_methods.grep(/\w+=/).collect {|x| x.to_s }

          if(klass.respond_to? :defined_activerecord_methods)
            setters = setters - klass.defined_activerecord_methods.to_a
          end

          # get into same format as other names 
          @@assignments[klass] += setters.map{|i| i.gsub(/=/, '')}
        end
        
        @@assignments[klass] -= @@has_many[klass] if(@@has_many[klass])
        @@assignments[klass] -= @@belongs_to[klass] if(@@belongs_to[klass])
        @@assignments[klass] -= self.has_one[klass] if(self.has_one[klass])
 
        @@assignments[klass].uniq!

        @@assignments[klass].each do |assign|
          @@column_types[klass] ||= {}
          column_def = klass.columns.find{ |col| col.name == assign }
          @@column_types[klass].merge!( assign => column_def) if column_def
        end
      end
    end

    def self.build_method_details( klass )
      assignments_for(klass).each do |n|
        @method_details[klass] << MethodDetail.new(n, klass, n, :assignment, klass.columns)
      end
        
      has_one_for(klass).each do |n|
        @method_details[klass] << MethodDetail.new(n, klass, n, :has_one)
      end
        
      has_many_for(klass).each do |n|
        @method_details[klass] << MethodDetail.new(n, klass, n, :has_many)
      end
        
      belongs_to_for(klass).each do |n|
        @method_details[klass] << MethodDetail.new(n, klass, n, :belongs_to)
      end
    end
    
    def self.method_details
      @method_details ||= {}
      @method_details
    end
    
    # Find the proper format of name, appropriate call + column type for a given name.
    # e.g Given users entry in spread sheet check for pluralization, missing underscores etc
    #
    # If not nil, returned method can be used directly in for example klass.new.send( call, .... )
    #
    def self.find_method_detail( klass, external_name )
      operator = nil

      name = external_name.to_s

      # TODO - check out regexp to do this work better plus Inflections ??
      # Want to be able to handle any of ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand" etc]
      [
        name,
        name.tableize,
        name.gsub(' ', '_'),
        name.gsub(' ', '_').downcase,
        name.gsub(/(\s+)/, '_').downcase,
        name.gsub(' ', ''),
        name.gsub(' ', '').downcase,
        name.gsub(' ', '_').underscore].each do |n|
      
        operator = (assignments_for(klass).include?(n)) ? n : nil
      
        return MethodDetail.new(name, klass, operator, :assignment, @@column_types[klass]) if(operator)

        operator = (has_one_for(klass).include?(n)) ? n : nil
      
        return MethodDetail.new(name, klass, operator, :has_one, @@column_types[klass]) if(operator)

        operator = (has_many_for(klass).include?(n)) ?  n : nil
      
        return MethodDetail.new(name, klass, operator, :has_many, @@column_types[klass]) if(operator)
      
        operator = (belongs_to_for(klass).include?(n)) ? n : nil
      
        return MethodDetail.new(name, klass, operator, :belongs_to, @@column_types[klass]) if(operator)
      
      end

      nil
    end

    def self.clear
      @@belongs_to.clear
      @@has_many.clear
      @@assignments.clear
      @@column_types.clear
      self.has_one.clear
    end

    def self.column_key(klass, column)
      "#{klass.name}:#{column}"
    end

    # TODO - remove use of class variables - not good Ruby design
    def self.belongs_to
      @@belongs_to
    end

    def self.has_many
      @@has_many
    end

    def self.has_one
      @has_one ||= {}
      @has_one
    end

    def self.assignments
      @@assignments
    end
    def self.column_types
      @@column_types
    end


    def self.belongs_to_for(klass)
      @@belongs_to[klass] || []
    end
    def self.has_many_for(klass)
      @@has_many[klass] || []
    end

    def self.has_one_for(klass)
      self.has_one[klass] || []
    end

    def self.assignments_for(klass)
      @@assignments[klass] || []
    end
    def self.column_type_for(klass, column)
      @@column_types[klass] ?  @@column_types[klass][column] : []
    end
  
  end

end