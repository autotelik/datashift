# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support CSV files.
# 
#
require 'loaders/loader_base'
require 'datashift/exceptions'
require 'datashift/method_mapper'

module DataShift
     
  module CsvLoading
    
    include DataShift::Logging
    
    # Options :
    #   strict : Raise exception if any column cannot be mapped
    
    def perform_csv_load(file_name, options = {})
       
      require "csv"

      # TODO - can we abstract out what a 'parsed file' is - so a common object can represent excel,csv etc
      # then  we can make load() more generic

      @parsed_file = CSV.read(file_name)

      # Create a method_mapper which maps list of headers into suitable calls on the Active Record class
      # For example if model has an attribute 'price' will map columns called Price, price, PRICE etc to this attribute
      map_headers_to_operators( @parsed_file.shift, options)

      puts "\n\n\nLoading from CSV file: #{file_name}"
      puts "Processing #{@parsed_file.size} rows"

      load_object_class.transaction do
        @loaded_objects =  []

        @parsed_file.each do |row|
          
          # First assign any default values for columns not included in parsed_file
          process_missing_columns_with_defaults

          # TODO - Smart sorting of column processing order ....
          # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
          # before associations can be processed so user should ensure mandatory columns are prior to associations

          # as part of this we also attempt to save early, for example before assigning to
          # has_and_belongs_to associations which require the load_object has an id for the join table

          # Iterate over the columns method_mapper found in Excel,
          # pulling data out of associated column
          @method_mapper.method_details.each_with_index do |method_detail, col|

            value = row[col]

            prepare_data(method_detail, value)
            
            process()
          end

          # TODO - handle when it's not valid ?
          # Process rest and dump out an exception list of Products ??

          logger.info "Saving csv row #{row} to table object : #{load_object.inspect}"

          save

          # don't forget to reset the object or we'll update rather than create
          new_load_object

        end
      end
    end
  end
  
  class CsvLoader < LoaderBase

    include DataShift::CsvLoading

    def initialize(klass, object = nil, options = {})
      super( klass, object, options )
      raise "Cannot load - failed to create a #{klass}" unless @load_object
    end

    def perform_load( file_name, options = {} )
      perform_csv_load( file_name, options )

      puts "CSV loading stage complete - #{loaded_objects.size} rows added."
    end

  end
    
end