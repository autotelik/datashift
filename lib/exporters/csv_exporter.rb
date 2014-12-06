# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'exporter_base'
require 'csv_file'

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

      records = [*export_records]

      unless(records && records.size > 0)
        logger.warn("No objects supplied for export")
        return
      end

      first = records[0]

      raise ArgumentError.new('Please supply set of ActiveRecord objects to export') unless(first.is_a?(ActiveRecord::Base))

      Delimiters.text_delim = options[:text_delim] if(options[:text_delim])

      CSV.open( (options[:filename] || filename), "w" ) do |csv|

        csv.ar_to_headers( records )

        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          csv.ar_to_csv(r, options)
        end
      end
    end

    # Create an Excel file from list of ActiveRecord objects
    # Specify which associations to export via :with or :exclude
    # Possible values are : [:assignment, :belongs_to, :has_one, :has_many]
    #
    def export_with_associations(klass, records, options = {})

      Delimiters.text_delim = options[:text_delim] if(options[:text_delim])

      MethodDictionary.find_operators( klass )

      MethodDictionary.build_method_details( klass )

      # For each type belongs has_one, has_many etc find the operators
      # and create headers, then for each record call those operators
      operators = options[:with] || MethodDetail::supported_types_enum

      CSV.open( (options[:filename] || filename), "w" ) do |csv|

        csv.ar_to_headers( records, operators)

        details_mgr = MethodDictionary.method_details_mgrs[klass]

        row = []

        records.each do |obj|

          operators.each do |op_type|

            operators_for_type = details_mgr.get_list(op_type)

            next if(operators_for_type.nil? || operators_for_type.empty?)

            operators_for_type.each do |md|
              if(MethodDetail.is_association_type?(op_type))
                row << record_to_column( obj.send( md.operator ))    # pack association into single column
              else
                row << escape_for_csv( obj.send( md.operator ) )
              end
            end
          end

          csv << row # next record
        end
      end

    end
  end
end
