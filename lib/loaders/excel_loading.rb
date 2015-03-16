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
module DataShift


  module ExcelLoading

    include ExcelBase

    # Currently struggling to determine the 'end' of data in a spreadsheet
    # this reflects if current row had any data at all
    attr_reader :contains_data

    #  Options  :
    #
    #   [:sheet_number]    : Default is 0. The index of the Excel Worksheet to use.
    #   [:header_row]      : Default is 0. Use alternative row as header definition.
    #
    def start( file_name, options = {} )

      puts "\n\nStarting Load from Excel file: #{file_name}"
      logger.info("\nStarting Load from Excel file: #{file_name}")

      start_excel(file_name, options[:sheet_number] || 0 )

      doc_context.headers = parse_headers(sheet, options[:header_row] || 0)

      raise MissingHeadersError, "No headers found - Check Sheet #{sheet} is complete and Row #{doc_context.headers.idx} contains headers" if(headers.empty?)

      # Create a method_mapper which maps list of headers into suitable calls on the Active Record class
      # For example if model has an attribute 'price' will map columns called Price or price or PRICE etc to this attribute
      bind_headers(headers, options )

      excel
    end

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

      start(file_name, options)

      begin
        puts "Dummy Run - Changes will be rolled back" if options[:dummy]

        load_object_class.transaction do

          sheet.each_with_index do |row, i|

            current_row_idx = i
            @current_row = row

            next if(current_row_idx == headers.idx)

            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # This is rubbish but currently manually detect when actual data ends, this isn't very smart but
            # got no better idea than ending once we hit the first completely empty row
            break if(@current_row.nil? || @current_row.compact.empty?)

            logger.info "Processing Row #{i} : #{@current_row}"

            @contains_data = false

            begin

              process_excel_row(row)

              # This is rubbish but currently have to manually detect when actual data ends,
              # no other way to detect when we hit the first completely empty row
              break unless(contains_data == true)

            rescue => e
              process_excel_failure(e, true)

              # don't forget to reset the load object
              new_load_object
              next
            end

            break unless(contains_data == true)

            # currently here as we can only identify the end of a speadsheet by first empty row
            @reporter.processed_object_count += 1

            # TODO - make optional -  all or nothing or carry on and dump out the exception list at end

            save_and_report

            # don't forget to reset the object or we'll update rather than create
            new_load_object

          end   # all rows processed

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

    def process_excel_failure( e, delete_object = true)
      failure(@current_row, delete_object)

      if(verbose)
        puts "perform_excel_load failed in row [#{current_row_idx}] #{@current_row} - #{e.message} :"
        puts e.backtrace
      end

      logger.error  "perform_excel_load failed in row [#{current_row_idx}] #{@current_row} - #{e.message} :"
      logger.error e.backtrace.join("\n")
    end


    def value_at(row, column)
      @excel[row, column]
    end

    def process_excel_row(row)

      # Iterate over the bindings, creating a context from data in associated Excel column

      @binder.bindings.each_with_index do |method_binding, i|

        unless(method_binding.valid?)
          logger.warn("No binding was found for column (#{i})") if(verbose)
          next
        end

        value = row[method_binding.inbound_index]   #binding contains column number

        @contains_data = true unless(value.nil? || value.to_s.empty?)

        @context = create_context(method_binding, i, value)

        logger.info "Processing Column #{method_binding.inbound_data.index} (#{method_binding.operator})"

        process(context, value)
      end

    end

  end

end