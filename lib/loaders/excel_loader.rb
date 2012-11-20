# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support Excel files.
#             Note this only requires JRuby, Excel not required, nor Win OLE.
#
#             Maps column headings to operations on the model.
#             Iterates over all the rows using mapped operations to assign row data to a database object,
#             i.e pulls data from each column and sends to object.
#
require 'datashift/exceptions'


module DataShift

  require 'loaders/loader_base'

  require 'excel'

  module ExcelLoading

    #  Options:
    #   [:dummy]           : Perform a dummy run - attempt to load everything but then roll back
    #  
    #   [:sheet_number]    : Default is 0. The index of the Excel Worksheet to use.
    #   [:header_row]      : Default is 0. Use alternative row as header definition.
    #   
    #  Options passed through  to :  populate_method_mapper_from_headers
    #  
    #   [:mandatory]       : Array of mandatory column names
    #   [:force_inclusion] : Array of inbound column names to force into mapping
    #   [:include_all]     : Include all headers in processing - takes precedence of :force_inclusion
    #   [:strict]          : Raise exception when no mapping found for a column heading (non mandatory)

    def perform_excel_load( file_name, options = {} )

      raise MissingHeadersError, "Minimum row for Headers is 0 - passed #{options[:header_row]}" if(options[:header_row] && options[:header_row].to_i < 0)
           
      @excel = Excel.new

      @excel.open(file_name)
        
      #if(options[:verbose])
      puts "\n\n\nLoading from Excel file: #{file_name}"

      sheet_number = options[:sheet_number] || 0
      
      @sheet = @excel.worksheet( sheet_number )

      header_row_index =  options[:header_row] || 0
      @header_row = @sheet.row(header_row_index)

      raise MissingHeadersError, "No headers found - Check Sheet #{@sheet} is complete and Row #{header_row_index} contains headers" unless(@header_row)

      @headers = []

      # TODO - make more robust - currently end on first empty column
      # There is no actual max columns in Excel .. you will run out of memory though at some point
      (0..1024).each do |column|
        cell = @header_row[column]
        break unless cell
        header = "#{cell.to_s}".strip
        break if header.empty?
        @headers << header
      end

      raise MissingHeadersError, "No headers found - Check Sheet #{@sheet} is complete and Row #{header_row_index} contains headers" if(@headers.empty?)
      
      # Create a method_mapper which maps list of headers into suitable calls on the Active Record class
      # For example if model has an attribute 'price' will map columns called Price, price, PRICE etc to this attribute
      populate_method_mapper_from_headers( @headers, options )
      
      logger.info "Excel Loader processing #{@sheet.num_rows} rows"
      
      loaded_objects.clear
      
      begin
            puts "Dummy Check", options.inspect
        puts "Dummy Run - Changes will be rolled back" if options[:dummy]
          
        load_object_class.transaction do
       
          @sheet.each_with_index do |row, i|
                 
            next if(i == header_row_index)
          
            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # This is rubbish but currently manually detect when actual data ends, this isn't very smart but
            # got no better idea than ending once we hit the first completely empty row
            break if row.nil?

            contains_data = false
            
            # First assign any default values for columns not included in parsed_file
            process_missing_columns_with_defaults

            # TODO - Smart sorting of column processing order ....
            # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
            # before associations can be processed so user should ensure mandatory columns are prior to associations

            # as part of this we also attempt to save early, for example before assigning to
            # has_and_belongs_to associations which require the load_object has an id for the join table
         
            # Iterate over method_details, working on data out of associated Excel column
            @method_mapper.method_details.each do |method_detail|
                
              next unless method_detail # TODO populate unmapped with a real MethodDetail that is 'null' and create is_nil
            
              value = row[method_detail.column_index]

              contains_data = true unless(value.nil? || value.to_s.empty?)
              
              prepare_data(method_detail, value)
              
              process()
            end
                          
            break unless(contains_data == true)

            # TODO - requirements to handle not valid ?
            # all or nothing or carry on and dump out the exception list at end
            #puts "DEBUG: FINAL SAVE #{load_object.inspect}"
            unless(save)
              failure
              logger.error "Failed to save row [#{row}]"
              logger.error load_object.errors.inspect if(load_object)
            else
              logger.info "Row #{row} succesfully SAVED : ID #{load_object.id}"
            end
            
            # don't forget to reset the object or we'll update rather than create
            new_load_object

          end
        
          raise ActiveRecord::Rollback if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run
        end
      
      rescue => e
        puts "CAUGHT ", e.inspect
        if e.is_a?ActiveRecord::Rollback && options[:dummy]
          puts "Excel loading stage complete - Dummy run so Rolling Back."
        else
          raise e
        end
      ensure
        report
      end
     
    end
    
    def value_at(row, column)
      @excel[row, column]
    end
    
  end


  class ExcelLoader < LoaderBase

    include ExcelLoading
  
    def initialize(klass, find_operators = true, object = nil, options = {})
      super( klass, find_operators, object, options )
      raise "Cannot load - failed to create a #{klass}" unless @load_object
    end


    def perform_load( file_name, options = {} )
      perform_excel_load( file_name, options )

      puts "Excel loading stage complete - #{loaded_objects.size} rows added."  
    end

  end
end