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

    # Load data through active Record models into DB from a CSV file
    #  
    # Assumes header_row is first row i.e row 0
    #   
    #   
    # OPTIONS :
    #  
    #  [:dummy]           : Perform a dummy run - attempt to load everything but then roll back
    #
    #  Options passed through  to :  populate_method_mapper_from_headers
    #  
    #   [:mandatory]       : Array of mandatory column names
    #   [:force_inclusion] : Array of inbound column names to force into mapping
    #   [:include_all]     : Include all headers in processing - takes precedence of :force_inclusion
    #   [:strict]          : Raise exception when no mapping found for a column heading (non mandatory)
    
    def perform_csv_load(file_name, options = {})
       
      require "csv"

      # TODO - can we abstract out what a 'parsed file' is - so a common object can represent excel,csv etc
      # then  we can make load() more generic

      @parsed_file = CSV.read(file_name)

      # Create a method_mapper which maps list of headers into suitable calls on the Active Record class
      # For example if model has an attribute 'price' will map columns called Price, price, PRICE etc to this attribute
      populate_method_mapper_from_headers( @parsed_file.shift, options)

      puts "\n\n\nLoading from CSV file: #{file_name}"
      puts "Processing #{@parsed_file.size} rows"
      begin
  
        load_object_class.transaction do
          @reporter.reset

          @parsed_file.each_with_index do |row, i|
            
            @current_row = row 
            
            @reporter.processed_object_count += 1
            
            begin
              # First assign any default values for columns not included in parsed_file
              process_defaults

              # TODO - Smart sorting of column processing order ....
              # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
              # before associations can be processed so user should ensure mandatory columns are prior to associations

              # as part of this we also attempt to save early, for example before assigning to
              # has_and_belongs_to associations which require the load_object has an id for the join table

              # Iterate over the columns method_mapper found in Excel,
              # pulling data out of associated column
              @method_mapper.method_details.each_with_index do |method_detail, col|

                unless method_detail
                  logger.warn("No method_detail found for col #{col} - These headings couldn't be mapped  #{@method_mapper.missing_methods.inspect}")
                  next # TODO populate unmapped with a real MethodDetail that is 'null' and create is_nil
                end
                
                value = row[col]

                #prepare_data(method_detail, value)
            
                process(method_detail, value)
              end

            rescue => e
              failure( row, true )
              logger.error "Failed to process row [#{i}] (#{@current_row})"
              
              if(verbose)
                puts "Failed to process row [#{i}] (#{@current_row})" 
                puts e.inspect 
              end
              
              # don't forget to reset the load object 
              new_load_object
              next
            end
            
            # TODO - make optional -  all or nothing or carry on and dump out the exception list at end        
            unless(save)
              failure
              logger.error "Failed to save row [#{@current_row}] (#{load_object.inspect})"
              logger.error load_object.errors.inspect if(load_object)
            else
              logger.info "Row #{@current_row} succesfully SAVED : ID #{load_object.id}"
              @reporter.add_loaded_object(@load_object)
            end

            # don't forget to reset the object or we'll update rather than create
            new_load_object

          end
        
          raise ActiveRecord::Rollback if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run
        end
      rescue => e
        logger.error "perform_csv_load failed - #{e.message}:\n#{e.backtrace}"
        if e.is_a?(ActiveRecord::Rollback) && options[:dummy]
          logger.info "CSV loading stage complete - Dummy run so Rolling Back."
        else
          raise e
        end
      ensure
        report
      end
    
    end
  end
  
  class CsvLoader < LoaderBase

    include DataShift::CsvLoading

    def initialize(klass, find_operators = true, object = nil, options = {})
      super( klass, find_operators, object, options )
      raise "Cannot load - failed to create a #{klass}" unless @load_object
    end

    def perform_load( file_name, options = {} )
      perform_csv_load( file_name, options )

      puts "CSV loading stage complete - #{loaded_count} rows added."
    end

  end
    
end