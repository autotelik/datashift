# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Module providing standard location for delimiters used in both export/import
#  
#             For example we support multiple entries in a single column, so the string 
#             needs to be formatted with recognisable delimiters seperating each of the multiple values.
#
module DataShift

  module Delimiters

    # I made these class methods, feeling delims are 'global'
    # I dunno now if thats good pattern or not


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


    # Support multiple associations being added to a base object to be specified in a single column.
    # 
    # Entry represents the association to find via supplied name, value to use in the lookup.
    # 
    # Default syntax :
    #
    #   Name1:value1, value2|Name2:value1, value2, value3|Name3:value1, value2
    #
    # E.G.
    #   Association Properties, has a column named Size, and another called Colour,
    #   and this combination could be used to lookup multiple associations to add to the main model Jumper
    #
    #       Size:small            # => generates find_by_size( 'small' )
    #       Size:large            # => generates find_by_size( 'large' )
    #       Colour:red,green,blue # => generates find_all_by_colour( ['red','green','blue'] )
    #
    #       Size:large|Size:medium|Size:large
    #         => Find 3 different associations, perform lookup via column called Size
    #         => Jumper.properties << [ small, medium, large ]
    #
    def self.name_value_delim
      @name_value_delim ||= ':'
      @name_value_delim
    end

    def self.set_name_value_delim(x)  @name_value_delim = x; end


    # The simple seperator for a list of values whether it be
    #     "Colour:red,green,blue".split(Delimiters::multi_value_delim) => [red,green,blue]
    #     {name => value, n2 => v2}.split(Delimiters::multi_value_delim) => [ [name => value], [n2 => v2] ]

    def self.multi_value_delim
      @multi_value_delim ||= ','
    end
    
    def self.set_multi_value_delim(x) @multi_value_delim = x; end

    # Objects can be created with multiple facets in single columns.
    # In this example a single Product can be configured with a consolidated mime and print types
    # 
    # mime_type:jpeg,PDF ; print_type:colour	 equivalent to 
    # 
    #   => mime_type:jpeg;print_type:colour | mime_type:PDF; print_type:colour
    
    def self.multi_facet_delim
      @multi_facet_delim ||= ';'
    end
    
    def self.setmulti_facet_delim(x) @multi_facet_delim = x; end
   
    
    # Multiple objects can be embedded in single columns.
    # In this example a single Category column contains 3 separate entries, New, SecondHand, Retro
    # object creation/update via hash (which hopefully we should be able to just forward to AR)
    #
    #      | Category |
    #      'name =>New, :a => 1, :b => 2|name => SecondHand, :a => 6, :b => 34|Name:Old, :a => 12, :b => 67', 'Next Column'
    #
    def self.multi_assoc_delim
      @multi_assoc_delim ||= '|'
      @multi_assoc_delim
    end

    def self.set_multi_assoc_delim(x) @multi_assoc_delim = x; end
    
    
    # Delimiters for {:abc => 2, :efg => 'some text}
    
    def self.attribute_list_start 
      @attribute_list_start ||= '{';
    end

    def self.attribute_list_start=(x) @attribute_list_start = x; end
    
    def self.attribute_list_end
      @attribute_list_end ||= '}'
    end
    
    def self.attribute_list_end=(x) 
      @attribute_list_end = x; 
    end
  
    def self.csv_delim
      @csv_delim ||= ','
      @csv_delim
    end
    
    def self.csv_delim=(x) set_csv_delim(x); end
    def self.set_csv_delim(x) @csv_delim = x; end

    def self.eol
      "\n"
    end

    # surround text in suitable quotes e.g "hello world, how are you" => ' "hello world, how are you" '
    def text_delim
      @text_delim ||= "\'"
    end

    def text_delim=(x)
      @text_delim = x
    end

    # seperator for identifying normal key value pairs

    def self.key_value_sep
      @key_value_sep ||= "=>"   #TODO check Ruby version and use appropriate has style ?
    end

    def self.key_value_sep=(x)
      @key_value_sep = x
    end

  end

end