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
require 'datashift/exceptions'

module DataShift

  require 'loaders/loader_base'

  require 'excel'

  module ExcelLoading

    include ExcelBase

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
        
      puts "\n\n\nLoading from Excel file: #{file_name}"

      sheet_number = options[:sheet_number] || 0
      
      @sheet = @excel.worksheet( sheet_number )

      parse_headers(@sheet, options[:header_row])

      raise MissingHeadersError, "No headers found - Check Sheet #{@sheet} is complete and Row #{header_row_index} contains headers" if(excel_headers.empty?)
      
      # Create a method_mapper which maps list of headers into suitable calls on the Active Record class
      # For example if model has an attribute 'price' will map columns called Price, price, PRICE etc to this attribute
      populate_method_mapper_from_headers( excel_headers, options )
      
      # currently pointless num_rows rubbish i.e inaccurate!
      #logger.info "Excel Loader processing #{@sheet.num_rows} rows"
      
      @reporter.reset
      
      begin
        puts "Dummy Run - Changes will be rolled back" if options[:dummy]
          
        load_object_class.transaction do
       
          @sheet.each_with_index do |row, i|
            
            @current_row = row 
            
            next if(i == header_row_index)
          
            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # This is rubbish but currently manually detect when actual data ends, this isn't very smart but
            # got no better idea than ending once we hit the first completely empty row
            break if(@current_row.nil? || @current_row.compact.empty?)
            
            logger.info "Processing Row #{i} : #{@current_row}"
            
            contains_data = false
            
            begin
              # First assign any default values for columns not included in parsed_file
              process_missing_columns_with_defaults

              # TODO - Smart sorting of column processing order ....
              # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
              # before associations can be processed so user should ensure mandatory columns are prior to associations

              # as part of this we also attempt to save early, for example before assigning to
              # has_and_belongs_to associations which require the load_object has an id for the join table
         
              # Iterate over method_details, working on data out of associated Excel column
              @method_mapper.method_details.each do |method_detail|
                    
                unless method_detail
                  logger.warn("No method_detail found - These headings couldn't be mapped  #{@method_mapper.missing_methods.inspect}")
                  next # TODO populate unmapped with a real MethodDetail that is 'null' and create is_nil
                end
                logger.info "Processing Column #{method_detail.column_index} (#{method_detail.operator})"
                
                value = @current_row[method_detail.column_index]

                contains_data = true unless(value.nil? || value.to_s.empty?)
              
                process(method_detail, value)           
              end
               
              # This is rubbish but currently have to manually detect when actual data ends, 
              # no other way to detect when we hit the first completely empty row
              break unless(contains_data == true)
                          
            rescue => e
              @reporter.processed_object_count += 1
              
              failure(@current_row, true)
              
              if(verbose)
                puts "perform_excel_load failed in row [#{i}] #{@current_row} - #{e.message} :" 
                puts e.backtrace
              end
              
              logger.error  "perform_excel_load failed in row [#{i}] #{@current_row} - #{e.message} :" 
              logger.error e.backtrace.join("\n")
              
              # don't forget to reset the load object 
              new_load_object
              next
            end
            
            break unless(contains_data == true)

            # currently here as we can only identify the end of a speadsheet by first empty row
            @reporter.processed_object_count += 1
                        
            # TODO - make optional -  all or nothing or carry on and dump out the exception list at end
            
            unless(save)
              failure
              logger.error "Failed to save row [#{@current_row}]"
              logger.error load_object.errors.inspect if(load_object)
            else
              logger.info "Row #{@current_row} succesfully SAVED : ID #{load_object.id}"
              @reporter.add_loaded_object(@load_object)
            end
            
            # don't forget to reset the object or we'll update rather than create
            new_load_object

          end
          
          if(options[:dummy])
            puts "Excel loading stage complete - Dummy run so Rolling Back."
            raise ActiveRecord::Rollback # Don't actually create/upload to DB if we are doing dummy run
          end
          
        end   # TRANSACTION N.B ActiveRecord::Rollback does not propagate outside of the containing transaction block
      
      rescue => e  
        puts "ERROR: Excel loading failed : #{e.inspect}"
        raise e
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
      
      logger.info "Starting bulk load from Excel : #{file_name}"
       
      perform_excel_load( file_name, options )

      puts "Excel loading stage complete - #{loaded_count} rows added."  
    end

  end
end