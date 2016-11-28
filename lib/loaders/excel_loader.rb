# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specific loader to support Excel files.
#             Note this only requires JRuby, Excel not required, nor Win OLE.
#
#             Maps column headings to operations on the model.
#             Iterates over all the rows using mapped operations to assign row data to a database object,
#             i.e pulls data from each column and sends to object.
#
require_relative 'file_loader'

module DataShift

  class ExcelLoader < LoaderBase

    include DataShift::ExcelBase
    include DataShift::FileLoader

    def initialize
      super
    end

    #  Options
    #
    #   [:sheet_name]      : Create a new worksheet assign to @sheet. Default is class.name
    #   [:sheet_number]    : Default is 0. The index of the Excel Worksheet to use.
    #
    def perform_load( options = {} )

      allow_empty_rows = DataShift::Loaders::Configuration.call.allow_empty_rows

      logger.info "Starting bulk load from Excel : #{file_name}"

      start(file_name, options)

      # maps list of headers into suitable calls on the Active Record class
      bind_headers(headers)

      is_dummy_run = DataShift::Configuration.call.dummy_run

      begin
        puts 'Dummy Run - Changes will be rolled back' if is_dummy_run

        load_object_class.transaction do
          sheet.each_with_index do |row, current_row_idx|

            next if current_row_idx == headers.idx

            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # manually have to detect when actual data ends, this isn't very smart but
            # got no better idea than ending once we hit the first completely empty row
            break if !allow_empty_rows && (row.nil? || row.empty?)

            logger.info "Processing Row #{current_row_idx}"

            contains_data = false

            doc_context.progress_monitor.start_monitoring

            # Iterate over the bindings,
            # For each column bound to a model operator, create a context from data in associated Excel column

            @binder.bindings.each do |method_binding|

              unless method_binding.valid?
                logger.warn("No binding was found for column (#{current_row_idx})")
                next
              end

              # If binding to a column, get the value from the cell (bindings can be to internal methods)
              value = method_binding.index ? row[method_binding.index] : nil

              context = doc_context.create_node_context(method_binding, current_row_idx, value)

              contains_data ||= context.contains_data?

              logger.info "Processing Column #{method_binding.index} (#{method_binding.pp})"

              begin
                context.process
              rescue
                if doc_context.all_or_nothing?
                  logger.error('All or nothing set and Current Column failed so complete Row aborted')
                  break
                end
              end

            end

            # Excel data rows not accurate, seems to have to manually detect when actual Excel data rows end
            break if !allow_empty_rows && contains_data == false

            doc_context.save_and_monitor_progress

            # unless next operation is update, reset the loader object
            doc_context.reset unless doc_context.node_context.next_update?
          end # all rows processed

          if is_dummy_run
            puts 'Excel loading stage done - Dummy run so Rolling Back.'
            raise ActiveRecord::Rollback # Don't actually create/upload to DB if we are doing dummy run
          end
        end # TRANSACTION N.B ActiveRecord::Rollback does not propagate outside of the containing transaction block

      rescue => e
        puts "ERROR: Excel loading failed : #{e.inspect}"
        raise e
      ensure
        report
      end

      puts 'Excel loading stage Complete.'
    end

    private

    #  Options  :
    #
    #   [:sheet_name]      : Create a new worksheet assign to @sheet. Default is class.name
    #   [:sheet_number]    : Default is 0. The index of the Excel Worksheet to use.
    #
    def start( file_name, options = {} )
      open_excel(file_name, options)

      header_row = DataShift::Loaders::Configuration.call.header_row

      set_headers( parse_headers(sheet, header_row) )

      if headers.empty?
        raise MissingHeadersError, "No headers found - Check Sheet #{sheet} is complete and Row #{headers.idx} contains headers"
      end

      excel
    end

  end
end
