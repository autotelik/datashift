# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to Excel '97(-2007) file format.
#
# TOD : Can we switch between .xls and XSSF (POI implementation of Excel 2007 OOXML (.xlsx) file format.)
#
#
module DataShift

  require 'exporter_base'

  require 'excel'

  class ExcelExporter < ExporterBase

    include DataShift::Logging
    include DataShift::ColumnPacker

    def initialize(filename)
      super(filename)
    end

    # Create an Excel file from list of ActiveRecord objects
    def export(export_records, options = {})

      records = [*export_records]

      unless(records && records.size > 0)
        logger.warn('Excel Export - No objects supplied for export - no file written')
        return
      end

      first = records[0]

      fail ArgumentError.new('Please supply set of ActiveRecord objects to export') unless(first.is_a?(ActiveRecord::Base))

      fail ArgumentError.new('Please supply array of records to export') unless records.is_a? Array

      logger.info("Exporting #{records.size} #{first.class} to Excel")

      @filename = options[:filename] if options[:filename]

      excel = prepare_excel(first.class, options)

      to_headers(first.class, options)

      excel.set_headers( headers )

      excel.ar_to_xls(records)

      logger.info("Writing Excel to file [#{filename}]")

      excel.write( filename )
    end

    # Create an Excel file from list of ActiveRecord objects, includes relationships
    #
    # Options
    #
    # [:filename] => Filename for generated template
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    #   Otherwise, defaults to including all association types defined by
    #   ModelMethod.supported_types_enum - which can be further refined by
    #
    # [:exclude] => List of association Types to EXCLUDE (:has_one etc)
    #
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    # [sheet_name:] - Name for worksheet, otherwise uses Class name
    #
    # [json:] - Export association data in single column in JSON format
    #
    def export_with_associations(klass, records, options = {})

      excel = prepare_excel(klass, options)

      collection = ModelMethods::Manager.catalog_class(klass)

      # with_associations - so over ride to default to :all if nothing specified
      options[:with] = :all if(options[:with].nil?)

      # sort out exclude etc
      options[:with] = op_types_in_scope( options )

      to_headers(klass, options)

      excel.set_headers( headers )

      logger.info("Wrote headers for #{klass} to Excel")

      row = 1

      logger.info("Processing #{records.size} records to Excel")

      records.each do |obj|
        column = 0

        # group columns by operator type
        options[:with].each do |op_type|
          collection.for_type(op_type).each do |model_method|
            # pack association instances into single column
            if(ModelMethod.is_association_type?(op_type))
              logger.info("Processing #{model_method.inspect} associations")
              excel[row, column] = record_to_column( obj.send( model_method.operator ), options )
            else
              excel[row, column] = obj.send( model_method.operator )
            end
            column += 1
          end
        end

        row += 1
      end

      logger.info("Writing Excel to file [#{filename}]")
      excel.write( filename )

    end

  end # ExcelGenerator

end # DataShift
