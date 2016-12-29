# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::
#
# A wrapper around creating and directly manipulating Excel files.
#
# i.e Create and populate XSL files
#
# jar added to class path in manifest - 'poi-3.5-beta4-20081128.jar'
#
if DataShift::Guards.jruby?

  require 'java'
  require 'poi-3.7-20101029.jar'

  require_relative 'ruby_poi_translations'

  class JExcelFile

    include RubyPoiTranslations
    extend RubyPoiTranslations

    include Enumerable

    java_import 'org.apache.poi.hssf.util.HSSFColor'
    java_import 'org.apache.poi.poifs.filesystem.POIFSFileSystem'

    java_import 'org.apache.poi.hssf.usermodel.HSSFCell'
    java_import 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
    java_import 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
    java_import 'org.apache.poi.hssf.usermodel.HSSFDataFormat'
    java_import 'org.apache.poi.hssf.usermodel.HSSFClientAnchor'
    java_import 'org.apache.poi.hssf.usermodel.HSSFRichTextString'

    attr_accessor :workbook, :row, :date_style
    attr_reader :sheet, :current_sheet_index

    # NOTE: this is the POI 3.7 HSSF maximum rows
    @@maxrows = 65535

    def self.maxrows
      @@maxrows
    end

    def self.date_format
      HSSFDataFormat.getBuiltinFormat('m/d/yy h:mm')
    end

    def self.open(file_name)
      HSSFWorkbook.new(FileInputStream.new(file_name))
    end

    # NOTES :
    #   The HSSFWorkbook uses 0 based indexes

    def initialize
      @workbook = HSSFWorkbook.new

      @sheet = nil
      @current_sheet_index = 0

      # The @patriarchs hash is a workaround because HSSFSheet.getDrawingPatriarch()
      # causes a lot of issues (if it doesn't throw an exception!)
      @patriarchs = {}

      @date_style = nil
    end

    def open(file_name)
      @workbook = JExcelFile.open(file_name)

      @date_style = @workbook.createCellStyle
      @date_style.setDataFormat( JExcelFile.date_format )

      activate_sheet(0)
      @workbook
    end

    # Create and return a new worksheet.
    # Not set to the active worksheet

    def create_worksheet( options = {} )
      sheet_name = options[:name]

      @workbook = HSSFWorkbook.new if @workbook.nil?

      if sheet_name

        name = sanitize_sheet_name( sheet_name )

        return create_sheet_and_set_styles( name ) if @workbook.getSheetIndex(name) < 0 # Check sheet doesn't already exist

        activate_sheet(name)

      else
        i = 0
        # there is no hard limit to no of sheets in Excel but at some point you will run out of memory!
        begin
          sheet_name = "Worksheet#{i += 1}"
        end while(@workbook.getSheetIndex(sheet_name) >= 0)

        return create_sheet_and_set_styles( sheet_name )
      end
    end

    # Set the supplied sheet index or name, as the active sheet and return it.
    # If no such sheet return current sheet
    def activate_sheet(term)

      if @workbook
        x = term.is_a?(String) ? @workbook.getSheetIndex(term.to_java(java.lang.String)) : term
        @sheet = worksheet(x)

        if @sheet
          @current_sheet_index = x
          @workbook.setActiveSheet(@current_sheet_index)
          @sheet = @workbook.getSheetAt(@current_sheet_index)
          @sheet.setActive(true)
        end
      end
      @sheet
    end

    # Return a sheet by index
    def worksheet( index )
      if @workbook
        x = index.is_a?(String) ? @workbook.getSheetIndex(index.to_java(java.lang.String)) : index
        return @workbook.getSheetAt(x)
      end
      nil
    end

    def worksheets
      (0...@workbook.getNumberOfSheets).collect { |i| @workbook.getSheetAt(i) }
    end

    # Create new row (indexing in line with POI usage, start 0)
    def create_row(index)
      return nil if @sheet.nil?
      raise 'BAD INDEX: Row indexing starts at 0' if index < 0
      @row = @sheet.createRow(index)
      @row
    end

    def num_rows
      @sheet.getPhysicalNumberOfRows
    end

    # Process each row. Row type is org.apache.poi.hssf.usermodel.HSSFRow

    # Currently ignores skip argument - TODO - this is how spreadsheet gem works
    # #each iterates over all used Rows (from the first used Row until
    # but omitting the first unused Row, see also #dimensions)
    # If the argument skip is given,
    # #each iterates from that row until but omitting the first unused Row,
    # effectively skipping the first skip Rows from the top of the Worksheet.

    def each(_skip = nil, &block)
      @sheet.rowIterator.each(&block)
    end

    def row( index )
      @sheet.getRow(index) || create_row(index)
    end

    # Get the enriched value of the Cell at row, column.
    def cell(row, column)
      row = row(row)
      cell_value( row.get_or_create_cell( column ) )
    end

    # Get the enriched value of the Cell at row, column.
    def [](row, column)
      cell(row, column)
    end

    def []=(row, column, value)
      set_cell(row, column, value)
    end

    def set_cell(row, column, value)
      @row = row(row)

      @row[column] = value
    end

    def sanitize_sheet_name( name )
      name.gsub(/[\[\]:\*\/\\\?]/, '')
    end

    def write( file_name = nil )
      file = file_name.nil? ? @filepath : file_name
      out = FileOutputStream.new(file)
      @workbook.write(out) unless @workbook.nil?
      out.close
    end

    alias save write

    def save_to_text( file_name )
      File.open( file_name, 'w') { |f| f.write(to_s) }
    end

    def to_s
      outs = ByteArrayOutputStream.new
      @workbook.write(outs)
      outs.close
      String.from_java_bytes(outs.toByteArray)
    end

    private

    def create_sheet_and_set_styles( sheet_name )

      name = sanitize_sheet_name(sheet_name)

      @sheet = @workbook.createSheet( name )

      @patriarchs.store(name, @sheet.createDrawingPatriarch)

      @date_style = @workbook.createCellStyle
      @date_style.setDataFormat( JExcelFile.date_format )
      @sheet
    end

  end

  require 'jexcel_file_extensions'
  require 'apache_poi_extensions'

end
