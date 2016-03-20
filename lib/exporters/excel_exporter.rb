# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Mar 2016
# License::   MIT
#
# Details::   Export a model to Excel '97(-2007) file format.
#
# TODO: Can we switch between .xls and XSSF (POI implementation of Excel 2007 OOXML (.xlsx) file format.)
#
#
module DataShift

  class ExcelExporter < ExporterBase

    include DataShift::Logging
    include DataShift::ColumnPacker

    include DataShift::ExcelBase

    def initialize
      super
    end

    # Create an Excel file from list of ActiveRecord objects
    def export(file_name, export_records, options = {})

      @file_name = file_name

      records = [*export_records]

      unless records && records.size > 0
        logger.warn('Excel Export - No objects supplied for export - no file written')
        return
      end

      first = records[0]

      raise ArgumentError.new('Please supply set of ActiveRecord objects to export') unless first.is_a?(ActiveRecord::Base)

      raise ArgumentError.new('Please supply array of records to export') unless records.is_a? Array

      logger.info("Exporting #{records.size} #{first.class} to Excel")

      excel = start_excel(first.class, options)

      klass_to_headers(first.class)

      excel.set_headers( headers )

      excel.ar_to_xls(records)

      logger.info("Writing Excel to file [#{file_name}]")

      excel.write( file_name )
    end

    # Create an Excel file from list of ActiveRecord objects, includes relationships
    #
    # Association Options -  See  lib/exporters/configuration.rb
    #
    def export_with_associations(file_name, klass, records)

      @file_name = file_name

      start_excel(klass)

      collection = ModelMethods::Manager.catalog_class(klass)

      # sort out exclude etc
      op_types_in_scope = configuration.op_types_in_scope

      klass_to_headers(klass)

      excel.set_headers( headers )

      logger.info("Wrote headers for #{klass} to Excel")

      row = 1

      logger.info("Processing #{records.size} records to Excel")

      model_methods = klass_to_model_methods( klass )

      records.each do |obj|
        column = 0

        model_methods.each do |model_method|
          # pack association instances into single column
          if model_method.association_type?
            logger.info("Processing #{model_method.inspect} associations")
            excel[row, column] = record_to_column( obj.send( model_method.operator ), configuration.json )
          else
            excel[row, column] = obj.send( model_method.operator )
          end
          column += 1
        end

        row += 1
      end

      logger.info("Writing Excel to file [#{file_name}]")
      excel.write( file_name )

    end

  end # ExcelGenerator

end # DataShift
