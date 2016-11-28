# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support CSV files.
#
#
require_relative 'file_loader'

module DataShift

  class CsvLoader < LoaderBase

    include DataShift::Logging
    include DataShift::FileLoader

    def initialize
      super
    end

    #  Options
    #
    #   [:allow_empty_rows]  : Default is to stop processing once we hit a completely empty row. Over ride.
    #                          WARNING maybe slow, as will process all rows as defined by Excel
    #
    #   [:dummy]           : Perform a dummy run - attempt to load everything but then roll back
    #
    #
    def perform_load( _options = {} )
      require 'csv'

      raise "Cannot load - failed to create a #{klass}" unless load_object

      logger.info "Starting bulk load from CSV : #{file_name}"

      # TODO: - can we abstract out what a 'parsed file' is - headers plus value of each node
      # so a common object can represent excel,csv etc
      # then  we can make load() more generic

      parsed_file = CSV.read(file_name)

      # assume headers are row 0
      header_idx = 0
      header_row = parsed_file.shift

      set_headers( DataShift::Headers.new(:csv, header_idx, header_row) )

      # maps list of headers into suitable calls on the Active Record class
      bind_headers(headers)

      begin
        puts 'Dummy Run - Changes will be rolled back' if(DataShift::Configuration.call.dummy_run)

        load_object_class.transaction do
          logger.info "Processing #{parsed_file.size} rows"

          parsed_file.each_with_index do |row, i|

            logger.info "Processing Row #{i} : #{row}"

            # Iterate over the bindings, creating a context from data in associated Excel column

            @binder.bindings.each_with_index do |method_binding, i|

              unless method_binding.valid?
                logger.warn("No binding was found for column (#{i}) [#{method_binding.pp}]")
                next
              end

              # If binding to a column, get the value from the cell (bindings can be to internal methods)
              value = method_binding.index ? row[method_binding.index] : nil

              context = doc_context.create_node_context(method_binding, i, value)

              logger.info "Processing Column #{method_binding.index} (#{method_binding.pp})"

              begin
                context.process
              rescue => x
                if doc_context.all_or_nothing?
                  logger.error('Complete Row aborted - All or nothing set and Current Column failed.')
                  logger.error(x.backtrace.first.inspect)
                  logger.error(x.inspect)
                  break
                end
              end
            end # end of each column(node)

            doc_context.save_and_monitor_progress

            doc_context.reset unless doc_context.node_context.next_update?
          end # all rows processed

          if(DataShift::Configuration.call.dummy_run)
            puts 'CSV loading stage done - Dummy run so Rolling Back.'
            raise ActiveRecord::Rollback # Don't actually create/upload to DB if we are doing dummy run
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
