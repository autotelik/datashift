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
    # => :filename
    # => :text_delim => Char to use to delim columns, useful when data contain embedded ','
    # => ::methods => List of methods to additionally call on each record
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

      CSV.open( (options[:filename] || filename), 'w' ) do |csv|
        csv << headers

        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          csv.ar_to_csv(r, options)
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
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def export_with_associations(klass, records, options = {})

      @filename = options[:filename] if options[:filename]

      Delimiters.text_delim = options[:text_delim] if(options[:text_delim])

      collection = ModelMethods::Manager.catalog_class(klass)

      # with_associations - so over ride to default to :all if nothing specified
      options[:with] = :all if(options[:with].nil?)

      # sort out exclude etc
      options[:with] = op_types_in_scope( options )

      to_headers(klass, options)

      CSV.open( (options[:filename] || filename), 'w' ) do |csv|
        csv << headers

        records.each do |obj|
          row = []

          # group columns by operator type
          op_types_in_scope( options ).each do |op_type|
            collection.for_type(op_type).each do |mm|
              # pack association instances into single column
              if(ModelMethod.is_association_type?(op_type))
                row << record_to_column( obj.send( mm.operator ))
              else
                row << escape_for_csv( obj.send( mm.operator ) )
              end
            end
          end
          csv << row # next record
        end
      end # end write file

    end
  end
end
