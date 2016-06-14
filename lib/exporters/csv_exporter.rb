# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Export a model to CSV
#
#

module DataShift

  class CsvExporter < ExporterBase

    include DataShift::Logging
    include DataShift::ColumnPacker

    def initialize
      super

      @csv_delimiter = ','
    end

    # Create CSV file from set of ActiveRecord objects
    #
    # Options :
    #
    # :csv_delim => Char to use to delim columns, useful when data contain embedded ','
    #
    def export(file_name, export_records, options = {})

      @file_name = file_name

      records = [*export_records]

      unless records && !records.empty?
        logger.warn('No objects supplied for export')
        return
      end

      first = records[0]

      raise ArgumentError.new('Please supply set of ActiveRecord objects to export') unless first.is_a?(ActiveRecord::Base)

      @csv_delimiter = options[:csv_delim] if options[:csv_delim]

      klass_to_headers(first.class)

      logger.debug "Writing out CSV Export. Columns delimited by [#{csv_delimiter}]"

      remove = DataShift::Transformer::Remove.remove_list

      CSV.open(file_name, 'w', col_sep: csv_delimiter ) do |csv|
        csv << headers.destinations

        records.each do |r|
          next unless r.is_a?(ActiveRecord::Base)
          csv.ar_to_row(r, remove)
        end
      end

      logger.info "CSV export completed for #{records.size} records"
    end

    # Create CSV file from list of ActiveRecord objects
    #
    # Options :
    #
    # :csv_delim => Char to use to delim columns, useful when data contain embedded ','
    #
    def export_with_associations(file_name, klass, records, options = {})

      @file_name = file_name

      @csv_delimiter = options[:csv_delim] if(options[:csv_delim])

      logger.info("Association Types in scope for export #{configuration.op_types_in_scope.inspect}")

      klass_to_headers(klass)

      model_methods = klass_to_model_methods( klass )

      logger.debug "Writing out CSV Export for #{klass} wioth Associations. Columns delimited by [#{csv_delimiter}]"

      CSV.open(file_name, 'w', col_sep: csv_delimiter ) do |csv|
        csv << headers.destinations

        records.each do |record|
          row = []

          model_methods.each do |model_method|
            row << if model_method.association_type?
                     record_to_column( record.send(model_method.operator) )
                   else
                     escape_for_csv( record.send(model_method.operator) )
                   end
          end
          csv.add_row(row)
        end
      end
    end # end write file

  end
end
