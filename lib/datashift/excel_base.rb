module DataShift

  module ExcelBase

    include DataShift::Logging

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

    # TODO: DRY
    def exportable?(record)
      return true if record.is_a?(ActiveRecord::Base)

      return true if Module.const_defined?(:Mongoid) && record.is_a?(Mongoid::Document)

      false
    end

    # Pass a set of AR records
    def ar_to_xls(records, start_row: 1, headers: nil, data_flow_schema: nil)
      return if !exportable?(records.first) || records.empty?

      # assume header row present
      row_index = start_row
      records.each do |record|
        ar_to_xls_row(row_index, record, headers: headers, data_flow_schema: data_flow_schema)
        row_index += 1
      end
    end

    # Save data from an AR record to the current row, based on the record's columns [c1,c2,c3]
    # Returns the number of the final column written to
    def ar_to_xls_row(row, record, start_column: 0, headers: nil, data_flow_schema: nil)

      column = start_column

      record_methods_to_call = if(data_flow_schema)
                                 data_flow_schema.sources
                               elsif headers.present?
                                 headers.collect(&:source)
                               else
                                 ModelMethods::Catalogue.column_names(record.class)
                               end
      record_methods_to_call.each do |method|
        ar_to_xls_cell(row, column, record, method)
        column += 1
      end
      column
    end

    # Expect to be able to send ar_method to the record i.e callable method to retrieve actual data to export

    def ar_to_xls_cell(row_idx, col_idx, record, ar_method)
      datum = record.send(ar_method)
      self[row_idx, col_idx] = datum
    rescue StandardError => e
      logger.error("Failed to export #{datum} from #{ar_method.inspect} to column #{col_idx}")
      logger.error(e.message)
      logger.error(e.backtrace)
    end
  end

end
