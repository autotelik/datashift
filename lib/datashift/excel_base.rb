module DataShift

  module ExcelBase

    def self.max_columns
      1024
    end

    attr_accessor :excel, :sheet

    #  Create @excel and set @sheet
    #
    # Options  :
    #
    #     :sheet_name : Create a new worksheet assign to @sheet.
    #                   Default is class.name
    #
    def start_excel(klass, options = {})

      @excel = DataShift::Excel.new

      name = options[:sheet_name] ? options[:sheet_name] : klass.name

      @sheet = excel.create_worksheet( name: name )

      unless sheet
        logger.error("Excel failed to create WorkSheet called [#{name}]")

        raise "Failed to create Excel WorkSheet called [#{name}]"
      end

      @excel
    end

    # Open excel file and assign to @excel and set @sheet
    #
    # Options  :
    #
    #     :sheet_name : Create a new worksheet assign to @sheet. Default is class.name
    #
    #     :sheet_number : Select the sheet by index - sheet_name takes precedence
    #
    def open_excel( file_name, options = {})

      @excel = DataShift::Excel.new

      @excel.open(file_name)

      if options[:sheet_name]

        @sheet = @excel.create_worksheet( name: options[:sheet_name] )

        unless sheet
          logger.error("Excel failed to create WorkSheet for #{name}")

          raise "Failed to create Excel WorkSheet for #{name}"
        end

      elsif options[:sheet_number]
        @sheet = @excel.worksheet( options[:sheet_number] )
      else
        @sheet = @excel.worksheets.first
      end

      @excel
    end

    def parse_headers( sheet, header_row_idx = 0 )

      headers = DataShift::Headers.new(:excel, header_row_idx)

      header_row = sheet.row(header_row_idx)
      unless header_row
        raise MissingHeadersError,
              "No headers found - Check Sheet #{sheet} is complete and Row #{header_row_idx} contains headers"
      end

      # TODO: - make more robust - currently end on first empty column
      # There is no actual max columns in Excel .. you will run out of memory though at some point
      (0..ExcelBase.max_columns).each do |column|
        cell = header_row[column]
        break unless cell
        header = cell.to_s.strip
        break if header.empty?
        headers << header
      end

      headers
    end

    def sanitize_sheet_name( name )
      name.gsub(/[\[\]:\*\/\\\?]/, '')
    end

    # Pass a set of AR records
    def ar_to_xls(records, options = {})
      return if !records.first.is_a?(ActiveRecord::Base) || records.empty?

      # assume headers present
      row_index = (options[:start_row]) ? (options[:start_row]) : 1

      records.each do |record|
        ar_to_xls_row(row_index, 0, record)

        row_index += 1
      end
    end

    # Save data from an AR record to the current row, based on the record's columns [c1,c2,c3]
    # Returns the number of the final column written to
    def ar_to_xls_row(row, start_column, record)
      return unless record.is_a?(ActiveRecord::Base)

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
      logger.error("Failed to export #{datum} from #{connection_column.inspect} to column #{column}")
      logger.error( e.message )
      logger.error(e.backtrace)

    end
  end

end
