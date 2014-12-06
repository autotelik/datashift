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
      @filename = filename
    end

    # Create an Excel file from list of ActiveRecord objects
    def export(export_records, options = {})

      records = [*export_records]

      unless(records && records.size > 0)
        logger.warn("No objects supplied for export")
        return
      end

      first = records[0]

      logger.info("Exporting #{records.size} #{first.class} to Excel")

      raise ArgumentError.new('Please supply set of ActiveRecord objects to export') unless(first.is_a?(ActiveRecord::Base))


      raise ArgumentError.new('Please supply array of records to export') unless records.is_a? Array

      excel = Excel.new

      if(options[:sheet_name] )
        excel.create_worksheet( :name => options[:sheet_name] )
      else
        excel.create_worksheet( :name => records.first.class.name )
      end

      excel.ar_to_headers(records)

      excel.ar_to_xls(records)

      excel.write( filename() )
    end

    # Create an Excel file from list of ActiveRecord objects
    # Specify which associations to export via :with or :exclude
    # Possible values are : [:assignment, :belongs_to, :has_one, :has_many]
    #   options[:sheet_name]

    def export_with_associations(klass, records, options = {})

      excel = Excel.new

      if(options[:sheet_name] )
        excel.create_worksheet( :name => options[:sheet_name] )
      else
        excel.create_worksheet( :name => records.first.class.name )
      end

      MethodDictionary.find_operators( klass )

      MethodDictionary.build_method_details( klass )

      # For each type belongs has_one, has_many etc find the operators
      # and create headers, then for each record call those operators
      operators = options[:with] || MethodDetail::supported_types_enum

      excel.ar_to_headers( records, operators)

      details_mgr = MethodDictionary.method_details_mgrs[klass]

      row = 1

      records.each do |obj|

        column = 0

        operators.each do |op_type|

          operators_for_type = details_mgr.get_list(op_type)

          next if(operators_for_type.nil? || operators_for_type.empty?)

          operators_for_type.each do |md|
            #puts "Add datum [#{obj.send( md.operator )}]"
            if(MethodDetail.is_association_type?(op_type))
              puts "Add  [#{md.operator}] - [#{obj.send( md.operator )}]"
              excel[row, column] = record_to_column( obj.send( md.operator ), to_json: true )    # pack association into single column
            else
              excel[row, column] = obj.send( md.operator )
            end
            column += 1
          end
        end

        row += 1
      end

      excel.write( filename() )

    end
  end # ExcelGenerator

end # DataShift