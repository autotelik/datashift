# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT
#
# Details::   This module acts as helpers for defining input/output file formats as classes.
#
# It provides a simple interface to define a file structure - field by field.
#
# By defining the structure, following methods and attributes are mixed in :
#
#   An attribute, with accessor for each field/column.
#   Parse a line, assigning values to each attribute.
#   Parse an instance of that file line by line, accepts a block in which data can be processed.
#   Method to split a file by field.
#   Method to perform replace operations on a file by field and value.
#
# Either delimited or a fixed width definition can be created via macro-like class methods :
#
#   create_field_definition [field_list]
#
#   create_fixed_definition {field => range }
#
# Member attributes, with getters and setters, can be added for each field defined above via class method :
#
#   create_field_attr_accessors
#
# USAGE :
#
# Create a class that contains definition of a file.
#
#   class ExampleFixedWith  < FileDefinitionBase
#     create_fixed_definition(:name => (0..7), :value => (8..15), :ccy => (16..18), :dr_or_cr => (19..19) )
#
#     create_field_attr_accessors
#   end
#
#   class ExampleCSV < FileDefinitionBase
#     create_field_definition %w{abc def  ghi jkl}
#
#     create_field_attr_accessors
#   end
#
# Any instance can then be used to parse the defined file type, with each field or column value
# being assigned automatically to the associated instance variable.
#
#   line = '1,2,3,4'
#   x = ExampleCSV.new( line )
#
#   assert x.responds_to? :jkl
#   assert_equal x.abc, '1'
#   assert_equal x.jkl.to_i, 4
#
module FileDefinitions

  include Enumerable

  attr_accessor :key
  attr_accessor :current_line

  # Set the delimiter to use when splitting a line - can be either a String, or a Regexp
  attr_writer :field_delim

  def initialize( line = nil )
    @key = ''
    parse(line) unless line.nil?
  end

  def self.included(base)
    base.extend(ClassMethods)
    subclasses << base
  end

  def self.subclasses
    @subclasses ||= []
  end

  # Return the field delimiter used when splitting a line
  def field_delim
    @field_delim || ','
  end

  # Parse each line of a file based on the field definition, yields self for each successive line
  #
  def each( file )
    File.new(file).each_line do |line|
      parse( line )
      yield self
    end
  end

  def fields
    @fields = self.class.field_definition.collect { |f| instance_variable_get "@#{f}" }
    @fields
  end

  def to_s
    fields.join(',')
  end

  module ClassMethods

    # Helper to generate methods to store and return the complete list of fields
    # in this File definition (also creates member @field_definition) and parse a line.
    #
    # e.g create_field_definition %w{ trade_id  drOrCr ccy costCentre postingDate amount }
    #
    def create_field_definition( *fields )
      instance_eval <<-end_eval
          @field_definition ||= %w{ #{fields.join(' ')} }
          def field_definition
            @field_definition
          end
      end_eval

      class_eval <<-end_eval
        def parse( line )
          @current_line = line
          before_parse  if respond_to? :before_parse
          @current_line.split(field_delim()).each_with_index {|x, i| instance_variable_set(\"@\#{self.class.field_definition[i]}\", x) }
          after_parse  if respond_to? :after_parse
          generate_key if respond_to? :generate_key
        end
      end_eval
    end

    def add_field(field, add_accessor = true)
      @field_definition ||= []
      @field_definition << field.to_s
      attr_accessor field  if add_accessor
    end

    # Helper to generate methods that return the complete list of fixed width fields
    # and associated ranges in this File definition, and parse a line.
    # e.g create_field_definition %w{ trade_id  drOrCr ccy costCentre postingDate amount }
    #
    def create_fixed_definition( field_range_map )

      unless field_range_map.is_a?(Hash)
        raise ArgumentError, 'Please supply hash to create_fixed_definition'
      end

      keys = field_range_map.keys.collect(&:to_s)
      string_map = Hash[*keys.zip(field_range_map.values).flatten]

      instance_eval <<-end_eval
        def fixed_definition
          @fixed_definition ||= #{string_map.inspect}
          @fixed_definition
        end
      end_eval

      instance_eval <<-end_eval
        def field_definition
          @field_definition ||= %w{  #{keys.join(' ')} }
          @field_definition
        end
      end_eval

      class_eval <<-end_eval
        def parse( line )
          @current_line = line
          before_parse  if respond_to? :before_parse
          self.class.fixed_definition.each do |key, range|
            instance_variable_set(\"@\#{key}\", @current_line[range])
          end
          after_parse  if respond_to? :after_parse
          generate_key if respond_to? :generate_key
        end
      end_eval

    end

    # Create accessors for each field
    def create_field_attr_accessors
      field_definition.each { |f| attr_accessor f }
    end

    ###############################
    # PARSING + FILE MANIPULATION #
    ###############################

    # Parse a complete file and return array of self, one per line
    def parse_file( file, options = {} )
      limit = options[:limit]
      count = 0
      lines = []
      File.new(file).each_line do |line|
        break if limit && ((count += 1) > limit)
        lines << new( line )
      end
      lines
    end

    # Split a file, whose field definition is represented by self,
    # into seperate streams, based on the values of one if it's fields.
    #
    # Writes the results, one file per split stream, to directory specified by output_path
    #
    # Options:
    #
    #   :keys       => Also write split files of the key fields
    #
    #   :filter     => Optional Regular Expression to act as filter be applid to the field.
    #                  For example split by Ccy but filter to only include certain ccys pass
    #                  filter => '[GBP|USD]'
    #
    def split_on_write( file_name, field, output_path, options = {} )

      path = output_path || '.'

      filtered = split_on( file_name, field, options )

      unless filtered.empty?
        log :info, "Writing seperate streams to #{path}"

        if options.key?(:keys)
          filtered.each do |strm, objects|
            RecsBase.write( { "keys_#{field}_#{strm}.csv" => objects.collect(&:key).join("\n") }, path)
          end
        end

        filtered.each do |strm, objects|
          RecsBase.write( { "#{field}_#{strm}.csv" => objects.collect(&:current_line).join("\n") }, path)
        end
      end
    end

    # Split a file, whose field definition is represented by self,
    # into seperate streams, based on one if it's fields.
    #
    # Returns a map of Field value => File def object
    #
    # We return the File Def object as this is now enriched, e.g with key fields, compared to the raw file.
    #
    # Users can get at the raw line simply by calling the line() method on File Def object
    #
    # Options:
    #
    #   :output_path => directory to write the individual streams files to
    #
    #   :filter      => Optional Regular Expression to act as filter be applid to the field.
    #                  For example split by Ccy but filter to only include certain ccys pass
    #                  filter => 'GBP|USD|EUR'
    #
    def split_on( file_name, field, options = {} )

      regex = options[:filter] ? Regexp.new(options[:filter]) : nil

      log :debug, "Using REGEX: #{regex.inspect}" if regex

      filtered = {}

      if new.respond_to?(field)

        log :info, "Splitting on #{field}"

        File.open( file_name ) do |t|
          t.each do |line|
            next unless line && line.chomp!
            x = new(line)

            value = x.send( field.to_sym ) # the actual field value from the specified field column
            next if value.nil?

            if regex.nil? || value.match(regex)
              filtered[value] ? filtered[value] << x : filtered[value] = [x]
            end
          end
        end
      else
        log :warn, "Field [#{field}] nor defined for file definition #{self.class.name}"
      end

      if options[:sort]
        filtered.values.each( &:sort )
        return filtered
      end
      filtered
    end

    # Open and parse a file, replacing a value in the specfied field.
    # Does not update the file itself. Does not write a new output file.
    #
    # Returns :
    #   1) full collection of updated lines
    #   2) collection of file def objects (self), with updated value.
    #
    # Finds values matching old_value in given map
    #
    # Replaces matches with new_value in map.
    #
    # Accepts more than one field, if files is either and array of strings
    # or comma seperated list of fields.
    #
    def file_set_field_by_map( file_name, fields, value_map, regex = nil )

      lines = []
      objects = []

      attribs = if fields.is_a?(Array)
                  fields
                else
                  fields.to_s.split(',')
                end

      attribs.collect! do |attrib|
        raise ArgumentError, "Field: #{attrib} is not a field on #{self.class.name}" unless new.respond_to?(attrib)
      end

      log :info, "#{self.class.name} - updating field(s) #{fields} in #{file_name}"

      File.open( file_name ) do |t|
        t.each do |line|
          if line.chomp.empty?
            lines << line
            objects << new
            next
          end
          x = new(line)

          attribs.each do |a|
            old_value = x.instance_variable_get( "@#{a}" )
            if value_map[old_value] || (regex && old_value.keys.detect { |k| k.match(regx) })
              x.instance_variable_set( "@#{a}", value_map[old_value] )
            end
          end

          objects << x
          lines << x.to_s
        end
      end

      [lines, objects]
    end
  end # END class methods

  # Open and parse a file, replacing a value in the specfied field.
  # Does not update the file itself. Does not write a new output file.
  #
  # Returns :
  #   1) full collection of updated lines
  #   2) collection of file def objects (self), with updated value.
  #
  # Finds values matching old_value, and also accepts an optional regex for more powerful
  # matching strategies of values on the specfified field.
  #
  # Replaces matches with new_value.
  #
  # Accepts more than one field, if files is either and array of strings
  # or comma seperated list of fields.
  #
  def file_set_field( file_name, field, old_value, new_value, regex = nil )

    map = { old_value => new_value }

    file_set_field_by_map(file_name, field, map, regex)
  end

end
