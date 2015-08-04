# To change this template, choose Tools | Templates
# and open the template in the editor.

module DataShift

  module ExcelBase

    def self.max_columns
      1024
    end

    attr_accessor :excel, :sheet

    #  Options  :
    #
    #
    def start_excel( file_name, sheet_number)

      @excel = Excel.new

      excel.open(file_name)

      @sheet = excel.worksheet( sheet_number )

      @excel
    end

    def parse_headers( sheet,  header_row_idx = 0 )

      headers = DataShift::Headers.new(:excel, header_row_idx)

      header_row = sheet.row(header_row_idx)

      fail MissingHeadersError, "No headers found - Check Sheet #{sheet} is complete and Row #{header_row_idx} contains headers" unless(header_row)

      # TODO: - make more robust - currently end on first empty column
      # There is no actual max columns in Excel .. you will run out of memory though at some point
      (0..ExcelBase.max_columns).each do |column|
        cell = header_row[column]
        break unless cell
        header = "#{cell}".strip
        break if header.empty?
        headers << header
      end

      headers
    end

    def sanitize_sheet_name( name )
      name.gsub(/[\[\]:\*\/\\\?]/, '')
    end

    # Helpers for dealing with Active Record models and collections
    # Specify array of operators/associations to include - possible values are :
    #     [:assignment, :belongs_to, :has_one, :has_many]

    def ar_to_headers( records, associations = nil )
      return if( !records.first.is_a?(ActiveRecord::Base) || records.empty?)

      headers = []

      if associations
        details_mgr = DataShift::MethodDictionary.method_details_mgrs[records.first.class]

        associations.each do |a|
          details_mgr.for_type(a).each { |md| headers << "#{md.operator}" }
        end if(details_mgr)

      else
        headers = records.first.class.columns.collect( &:name )
      end

      set_headers( headers )
    end

    # Pass a set of AR records
    def ar_to_xls(records, options = {})
      return if( !records.first.is_a?(ActiveRecord::Base) || records.empty?)

      row_index =
          if(options[:no_headers])
            0
          else
            ar_to_headers( records )
            1
          end

      records.each do |record|
        ar_to_xls_row(row_index, 0, record)

        row_index += 1
      end
    end

    # Save data from an AR record to the current row, based on the record's columns [c1,c2,c3]
    # Returns the number of the final column written to
    def ar_to_xls_row(row, start_column, record)
      return unless( record.is_a?(ActiveRecord::Base))

      column = start_column
      record.class.columns.each do |connection_column|
        ar_to_xls_cell(row, column, record, connection_column)
        column += 1
      end
      column
    end

    def ar_to_xls_cell(row, column, record, connection_column)

      datum = record.send(connection_column.name)

      self[row, column] = datum
    rescue => e
      puts "Failed to export #{datum} from #{connection_column.inspect} to column #{column}"
      puts e, e.backtrace

    end
  end

end
