# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::
#
# Details::   A helper module providing shortcuts for manipulating Excel files.
#

if DataShift::Guards.jruby?

  JExcelFile.class_eval do
    java_import 'org.apache.poi.hssf.util.HSSFColor'

    # Return the current active sheet
    # If term supplied find sheet and set active
    #
    def active_worksheet(term = nil)
      if @workbook
        if term.nil?
          @sheet ||= @workbook.getSheetAt(@current_sheet_index)
        else
          activate_sheet(term)
        end
      end
      @sheet
    end

    #  Populate a row  of cells with data in an array
    #  where the co-ordinates relate to row/column start position
    #
    def set_row( row, col, data, sheet_num = nil)

      sheet(sheet_num)

      create_row(row)

      column = col
      data.each do |datum|
        set_cell(row, column, datum)
        column += 1
      end
    end

    # Convert array into a header row
    def set_headers(headers, apply_style = nil)
      create_row(0)
      return if headers.empty?

      style = apply_style || header_style

      headers.sources.each_with_index do |datum, i|
        c = @row.createCell(i, poi_cell_type(datum))
        c.setCellValue(datum)
        c.setCellStyle(style)
      end
    end

    attr_writer :header_background_colour

    def header_background_colour
      @header_background_colour ||= org.apache.poi.hssf.util.HSSFColor::LIGHT_CORNFLOWER_BLUE.index
    end

    def header_style
      return @header_style if @header_style
      @header_style = @workbook.createCellStyle
      @header_style.setBorderTop(6) # double lines border
      @header_style.setBorderBottom(1) # single line border
      @header_style.setFillBackgroundColor(header_background_colour)

      @header_style
    end

    def add_comment( cell, text )
      raise 'Please supply valid HSSFCell' unless cell.respond_to?('setCellComment')
      return if @sheet.nil?

      patriarch = @patriarchs[@sheet.getSheetName]

      anchor = HSSFClientAnchor.new(100, 50, 100, 50, cell.getColumnIndex, cell.getRowIndex, cell.getColumnIndex + 3, cell.getRowIndex + 4)
      comment = patriarch.createCellComment(anchor)

      comment_text = HSSFRichTextString.new(text)
      comment.setString(comment_text)
      comment.setAuthor('Mapping')

      cell.setCellComment(comment)
    end

    # Get a percentage style
    def getPercentStyle
      if @percentCellStyle.nil? && @workbook
        @percentCellStyle = @workbook.createCellStyle
        @percentCellStyle.setDataFormat(HSSFDataFormat.getBuiltinFormat('0.00%'))
      end
      @percentCellStyle
    end

    # Auto size either the given column index or all columns
    def autosize(column = nil)
      return if @sheet.nil?
      if column.is_a? Integer
        @sheet.autoSizeColumn(column)
      else
        @sheet.getRow(0).cellIterator.each { |c| @sheet.autoSizeColumn(c.getColumnIndex) }
      end
    end

    def create_freeze_pane(row = 1, column = 0)
      return if @sheet.nil?
      @sheet.createFreezePane(row, column)
    end

    # Use execute to run sql query provided
    # and write to a csv file (path required)
    # header row is optional but default is on
    # Auto mapping of specified columns is optional
    # @mappings is a hash{column => map} of columns to a map{old_value => new_value}
    def results_to_sheet( results, sheet, mappings = nil, header = true)
      numrows = results.length
      sheet_name = sheet

      if numrows == 0
        log :info, "WARNING - results are empty nothing written to sheet: #{sheet}"
        return
      end

      # Check if we need to split the results into seperate sheets
      if numrows > @@maxrows
        startrow = 0
        while numrows > 0
          # Split the results and write to a new sheet
          slice_at = @@maxrows > numrows ? numrows : @@maxrows
          next_results = results.slice(startrow, slice_at)
          results_to_sheet(next_results, sheet_name.to_s, mappings, header) if next_results

          # Increase counters
          numrows -= next_results.length
          startrow += next_results.length
          sheet_name += 'I'
        end
      else
        log :info, "Writting #{numrows} rows to : #{sheet_name}"
        # Create required sheet
        create(sheet)

        row_index = num_rows
        # write header line
        if header && row_index == 0
          header_row = @sheet.createRow(row_index)
          cell_index = 0
          results[0].keys.each do |h|
            header_row.createCell(cell_index).setCellValue(h.to_s)
            @sheet.setDefaultColumnStyle(cell_index, getPercentStyle) if h.to_s.include? '%'
            cell_index += 1
          end
          # Freeze the header row
          @sheet.createFreezePane( 0, 1, 0, 1 )
          row_index += 1
        end

        # write_results
        results.each do |row|
          sheet_row = @sheet.createRow(row_index)
          cell_index = 0
          row.each do |_k, v|
            celltype = v.is_a?(Numeric) ? HSSFCell::CELL_TYPE_NUMERIC : HSSFCell::CELL_TYPE_STRING
            cell = sheet_row.createCell(cell_index, celltype)

            value = v.nil? ? '<NIL>' : v

            cell.setCellValue(value)

            cell_index += 1
          end
          # puts "#{sheet}: written row #{row_index}"
          row_index += 1
        end
      end
    end

    module ExcelHelper
      require 'java'

      java_import 'org.apache.poi.poifs.filesystem.POIFSFileSystem'
      java_import 'org.apache.poi.hssf.usermodel.HSSFCell'
      java_import 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
      java_import 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
      java_import 'org.apache.poi.hssf.usermodel.HSSFDataFormat'
      java_import 'java.io.ByteArrayOutputStream'
      java_import 'java.util.Date'

      # ActiveRecord Helper - Export model data to XLS file format
      #
      def to_xls(items = [])

        @excel = ExcelFile.new(items[0].class.name)

        @excel.create_row(0)

        sheet = @excel.sheet

        # header row
        unless items.empty?
          row = sheet.createRow(0)
          cell_index = 0
          items[0].class.columns.each do |column|
            row.createCell(cell_index).setCellValue(column.name)
            cell_index += 1
          end
        end

        # value rows
        row_index = 1
        items.each do |item|
          row = sheet.createRow(row_index)

          cell_index = 0
          item.class.columns.each do |column|
            cell = row.createCell(cell_index)
            if column.sql_type =~ /date/
              millis = item.send(column.name).to_f * 1000
              cell.setCellValue(Date.new(millis))
              cell.setCellStyle(dateStyle)
            elsif column.sql_type =~ /int/
              cell.setCellValue(item.send(column.name).to_i)
            else
              value = item.send(column.name)
              cell.setCellValue(item.send(column.name)) unless value.nil?
            end
            cell_index += 1
          end
          row_index += 1
        end
        @excel.to_s
      end
    end
  end
end
