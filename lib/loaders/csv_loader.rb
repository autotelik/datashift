# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support CSV files.
#
#
module DataShift

  class CsvLoader < LoaderBase

    include DataShift::Logging
    include DataShift::FileLoader

    # Setup loading
    #
    # Options to drive building the method dictionary for a class, enabling headers to be mapped to operators on that class.
    #
    # Options
    #  :verbose          : Verbose logging and to STDOUT
    #
    def initialize( file_name, options = {} )
      super( options )

      @file_name = file_name
    end

    #  Options
    #
    #   [:allow_empty_rows]  : Default is to stop processing once we hit a completely empty row. Over ride.
    #                          WARNING maybe slow, as will process all rows as defined by Excel
    #
    #   [:dummy]           : Perform a dummy run - attempt to load everything but then roll back
    #
    #   [:sheet_number]    : Default is 0. The index of the Excel Worksheet to use.
    #
    #  Options passed through  to :  populate_method_mapper_from_headers
    #
    #   [:mandatory]       : Array of mandatory column names
    #   [:force_inclusion] : Array of inbound column names to force into mapping
    #   [:include_all]     : Include all headers in processing - takes precedence of :force_inclusion

    def perform_load( options = {} )

      require 'csv'

      fail "Cannot load - failed to create a #{klass}" unless(load_object)

      allow_empty_rows = options[:allow_empty_rows]

      logger.info "Starting bulk load from CSV : #{file_name}"

      # TODO: - can we abstract out what a 'parsed file' is - heades plus value of each node
      # so a common object can represent excel,csv etc
      # then  we can make load() more generic

      parsed_file = CSV.read(file_name)

      set_headers( DataShift::Headers.new(:csv, 0, parsed_file.shift ) )

      # maps list of headers into suitable calls on the Active Record class
      bind_headers(headers, options.merge({ strict: @strict }) )

      begin
        puts 'Dummy Run - Changes will be rolled back' if options[:dummy]

        load_object_class.transaction do
          puts "\n\n\nLoading from CSV file: #{file_name}"
          puts "Processing #{parsed_file.size} rows"

          parsed_file.each_with_index do |row, i|
            current_row_idx = i

            doc_context.current_row = row

            next if(current_row_idx == headers.idx)

            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # manually have to detect when actual data ends, this isn't very smart but
            # got no better idea than ending once we hit the first completely empty row
            break if(!allow_empty_rows && (row.nil? || row.empty?))

            logger.info "Processing Row #{i} : #{@current_row}"

            contains_data = false

            # Iterate over the bindings, creating a context from data in associated Excel column

            @binder.bindings.each_with_index do |method_binding, i|
              unless(method_binding.valid?)
                logger.warn("No binding was found for column (#{i})")
                next
              end

              value = row[method_binding.inbound_index] # binding contains column number

              context = doc_context.create_context(method_binding, i, value)

              contains_data ||= context.contains_data?

              logger.info "Processing Column #{method_binding.inbound_index} (#{method_binding.pp})"

              begin
                context.process
              rescue => x
                if(doc_context.all_or_nothing?)
                  logger.error('Node failed so Current Row aborted')
                  break
                end
              end
            end

            # manually have to detect when actual data ends
            break if(!allow_empty_rows && contains_data == false)

            unless(doc_context.errors? && doc_context.all_or_nothing?)
              doc_context.save_and_report
            end

            doc_context.reset unless doc_context.context.next_update?
          end # all rows processed

          if(options[:dummy])
            puts 'CSV loading stage done - Dummy run so Rolling Back.'
            fail ActiveRecord::Rollback # Don't actually create/upload to DB if we are doing dummy run
          end
        end # TRANSACTION N.B ActiveRecord::Rollback does not propagate outside of the containing transaction block

      rescue => e
        puts "ERROR: CSV loading failed : #{e.inspect}"
        raise e
      ensure
        report
      end

      puts 'CSV loading stage Complete.'
    end

  end
end
