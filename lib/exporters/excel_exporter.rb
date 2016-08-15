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

    # Pptional, otherwise  uses the standard collection of Model Methods for supplied klass

    attr_accessor :data_flow_schema

    def initialize
      super

      @data_flow_schema = nil
    end

    # Create an Excel file from list of ActiveRecord objects
    def export(file_name, export_records, options = {})

      @file_name = file_name

      records = [*export_records]

      if(records.nil? || records.empty?)
        logger.warn('Excel Export - No objects supplied for export - no file written')
        return
      end

      first = records[0]

      raise(ArgumentError, 'Please supply set of ActiveRecord objects to export') unless first.is_a?(ActiveRecord::Base)

      logger.info("Exporting #{records.size} #{first.class} to Excel")

      excel = start_excel(first.class, options)

      excel.ar_to_xls(records)

      logger.info("Writing Excel to file [#{file_name}]")

      excel.write( file_name )
    end


    def preprare_data_flow_schema( klass )
      logger.info("Wrote headers for #{klass} to Excel")

      if(data_flow_schema)
        excel.set_headers( data_flow_schema.destinations )
      else
        @data_flow_schema = DataShift::DataFlowSchema.new
        @data_flow_schema.prepare_from_klass( klass )

        klass_to_headers(klass)
        excel.set_headers( headers.destinations )
      end

      data_flow_schema
    end

    # Create an Excel file from list of ActiveRecord objects, includes relationships
    #
    # Association Options -  See  lib/exporters/configuration.rb
    #
    def export_with_associations(file_name, klass, records, options = {})

      @file_name = file_name

      excel = start_excel(klass, options)

      preprare_data_flow_schema( klass )

      logger.info("Processing #{records.size} records to Excel")

      model_methods = data_flow_schema.nodes

      row = 1

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
