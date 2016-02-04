# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'exporter_base'

module DataShift

  class CsvExporter < ExporterBase

    include DataShift::Logging
    include DataShift::ColumnPacker

    def initialize(filename)
      super(filename)
    end

    # Create CSV file from set of ActiveRecord objects
    # Options :
    # :filename
    # :text_delim   => Char to use to delim columns, useful when data contain embedded ','
    # :methods      => List of methods to additionally call on each record
    # :remove       => List of columns to remove from generated template
    #
    def export(export_records, options = {})

      @filename = options[:filename] if options[:filename]

      records = [*export_records]

      unless(records && records.size > 0)
        logger.warn('No objects supplied for export')
        return
      end

      first = records[0]

      fail ArgumentError.new('Please supply set of ActiveRecord objects to export') unless(first.is_a?(ActiveRecord::Base))

      Delimiters.text_delim = options[:text_delim] if(options[:text_delim])

      to_headers(first.class, options)

      remove = options[:remove] || []

      CSV.open( (options[:filename] || filename), 'w' ) do |csv|
        csv << headers

        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          csv.ar_to_row(r, remove, options)
        end
      end
    end

    # Create CSV file from list of ActiveRecord objects
    #
    # Options
    # [:filename] => Filename for generated template
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    #   Otherwise, defaults to including ALL association types defined by
    #   ModelMethod.supported_types_enum - which can be further refined by
    #
    # [:exclude] => List of association Types to exclude (:has_one etc)
    #
    # [:remove] => List of columns to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def export_with_associations(klass, records, options = {})

      @filename = options[:filename] if options[:filename]

      Delimiters.text_delim = options[:text_delim] if(options[:text_delim])

      collection = ModelMethods::Manager.catalog_class(klass)

      # We need to default to :all if nothing specified
      options[:with] ||= :all

      types_in_scope = op_types_in_scope( options )

      logger.info("Association Types in scope for export #{types_in_scope.inspect}")

      to_headers(klass, { with: types_in_scope, remove: options[:remove] })

      # do the main model first, as per to_headers
      assignment = types_in_scope.delete(:assignment)

      remove_list = options[:remove] || []

      CSV.open( (options[:filename] || filename), 'w' ) do |csv|
        csv << headers

        records.each do |record|
          row = []

          row += csv.ar_to_csv(record, remove_list, options) if(assignment)

          # group columns by operator type
          types_in_scope.each do |op_type|

            # now find all related columns (wrapped in ModelMethod) by operator type
            collection.for_type(op_type).each do |model_method|

              next if(remove_list.include?(model_method.operator.to_sym))

              #row << csv.ar_association_to_csv(record, model_method, options)

              if(DataShift::ModelMethod.is_association_type?(model_method.operator_type))
                row << record_to_column( record.send(model_method.operator) )
              else
                row << escape_for_csv( record.send(model_method.operator) )
              end

            end
          end

          csv.add_row(row)
        end
      end # end write file

    end
  end
end
