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

      unless records && records.size > 0
        logger.warn('No objects supplied for export')
        return
      end

      first = records[0]

      raise ArgumentError.new('Please supply set of ActiveRecord objects to export') unless first.is_a?(ActiveRecord::Base)

      if(options[:csv_delim])
        @csv_delimiter = options[:csv_delim]
      end

      klass_to_headers(first.class)

      remove =  DataShift::Exporters::Configuration.configuration.remove

      logger.debug "CSV columns delimited by [#{options[:csv_delim]}] [#{csv_delimiter}]"

      CSV.open(file_name, "w", col_sep: csv_delimiter ) do |csv|
        csv << headers

        records.each do |r|
          next unless r.is_a?(ActiveRecord::Base)
          csv.ar_to_row(r, remove, options)
        end
      end
    end

    # Create CSV file from list of ActiveRecord objects
    #
    # Options :
    #
    # :csv_delim => Char to use to delim columns, useful when data contain embedded ','
    #
    def export_with_associations(file_name, klass, records, options = {})

      @file_name = file_name

      csv_delim = options[:csv_delim] if(options[:csv_delim]) if(options[:csv_delim])

      collection = ModelMethods::Manager.catalog_class(klass)

      types_in_scope = configuration.op_types_in_scope

      logger.info("Association Types in scope for export #{types_in_scope.inspect}")

      klass_to_headers(klass)

      # do the main model first, as per to_headers
      assignment = types_in_scope.delete(:assignment)

      remove_list = options[:remove] || []

      CSV.open( (options[:file_name] || file_name), 'w' ) do |csv|
        csv << headers

        records.each do |record|
          row = []

          row += csv.ar_to_csv(record, remove_list, options) if assignment

          # group columns by operator type
          types_in_scope.each do |op_type|

            # now find all related columns (wrapped in ModelMethod) by operator type
            collection.for_type(op_type).each do |model_method|

              next if remove_list.include?(model_method.operator.to_sym)

              # row << csv.ar_association_to_csv(record, model_method, options)

              row << if DataShift::ModelMethod.association_type?(model_method.operator_type)
                       record_to_column( record.send(model_method.operator) )
                     else
                       escape_for_csv( record.send(model_method.operator) )
                     end

            end
          end

          csv.add_row(row)
        end
      end # end write file

    end
  end
end
