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

  if(Guards::jruby?)

    require 'loaders/loader_base'

    require 'java'
    require 'jexcel_file'

    module ExcelLoading

      #  Options:
      #   [:sheet_number]    : Default is 0. The index of the Excel Worksheet to use.
      #   [:header_row]      : Default is 0. Use alternative row as header definition.
      #   [:mandatory]       : Array of mandatory column names
      #   [:force_inclusion] : Array of inbound column names to force into mapping
      #   [:strict]          : Raise exception when no mapping found for a column heading (non mandatory)


      def perform_excel_load( file_name, options = {} )

        @excel = JExcelFile.new

        @excel.open(file_name)
        
        #if(options[:verbose])
        puts "\n\n\nLoading from Excel file: #{file_name}"

        sheet_number = options[:sheet_number] || 0

        @sheet = @excel.sheet( sheet_number )

        header_row_index =  options[:header_row] || 0
        @header_row = @sheet.getRow(header_row_index)

        raise MissingHeadersError, "No headers found - Check Sheet #{@sheet} is complete and Row #{header_row_index} contains headers" unless(@header_row)

        @headers = []

        (0..JExcelFile::MAX_COLUMNS).each do |i|
          cell = @header_row.getCell(i)
          break unless cell
          header = "#{@excel.cell_value(cell).to_s}".strip
          break if header.empty?
          @headers << header
        end

        raise MissingHeadersError, "No headers found - Check Sheet #{@sheet} is complete and Row #{header_row_index} contains headers" if(@headers.empty?)

        # Create a method_mapper which maps list of headers into suitable calls on the Active Record class
        # For example if model has an attribute 'price' will map columns called Price, price, PRICE etc to this attribute
        map_headers_to_operators( @headers, options )

        logger.info "Excel Loader prcoessing #{@excel.num_rows} rows"
        load_object_class.transaction do
          @loaded_objects =  []

          (1..@excel.num_rows).collect do |row|

            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # This is rubbish but currently manually detect when actual data ends, this isn't very smart but
            # got no better idea than ending once we hit the first completely empty row
            break if @excel.sheet.getRow(row).nil?

            contains_data = false
            
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

              value = value_at(row, col)

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
              logger.error load_object.errors.inspect
            else
              logger.info "Row #{row} succesfully SAVED : ID #{load_object.id}"
            end
            
            # don't forget to reset the object or we'll update rather than create
            new_load_object

          end
        end
        puts "Excel loading stage complete - #{loaded_objects.size} rows added."
      end

      def value_at(row, column)
        @excel.get_cell_value( @excel.sheet.getRow(row), column)
      end
    end


    class ExcelLoader < LoaderBase

      include ExcelLoading
  
      def initialize(klass, object = nil, options = {})
        super( klass, object, options )
        raise "Cannot load - failed to create a #{klass}" unless @load_object
      end


      def perform_load( file_name, options = {} )
        perform_excel_load( file_name, options )

        puts "Excel loading stage complete - #{loaded_objects.size} rows added."  
      end

    end
  
  else
  
    module ExcelLoading 
    end
  
  end
  
end