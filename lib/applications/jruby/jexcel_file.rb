# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# An Excel file helper. Create and populate XSL files
#
# The maximum number of columns and rows in an Excel file is fixed at 256 Columns and 65536 Rows
# 
# POI jar location needs to be added to class path.
#
#  TODO -  Check out http://poi.apache.org/poi-ruby.html
#
if(DataShift::Guards::jruby?)

  require "poi-3.7-20101029.jar"

  class JExcelFile
    
    java_import org.apache.poi.poifs.filesystem.POIFSFileSystem

    include_class 'org.apache.poi.hssf.usermodel.HSSFCell'
    include_class 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
    include_class 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
    include_class 'org.apache.poi.hssf.usermodel.HSSFDataFormat'
    include_class 'org.apache.poi.hssf.usermodel.HSSFClientAnchor'
    include_class 'org.apache.poi.hssf.usermodel.HSSFRichTextString'

    include_class 'java.io.ByteArrayOutputStream'
    include_class 'java.util.Date'
    include_class 'java.io.FileInputStream'
    include_class 'java.io.FileOutputStream'

    attr_accessor :book, :row, :date_style
    attr_reader   :sheet

    MAX_COLUMNS = 256.freeze unless defined?(MAX_COLUMNS)

    def self.date_format
      HSSFDataFormat.getBuiltinFormat("m/d/yy h:mm")
    end
    
    # NOTE: this is the POI 3.7 HSSF maximum rows
    def self.maxrows
      return 65535
    end

    # The HSSFWorkbook uses 0 based indexes, whilst our companion jexcel_win32 class
    # uses 1 based indexes. So they can be used interchangeably we bring indexes 
    # inline with  JExcel usage in this class, as 1 based maps more intuitively for the user
    # 
    # i.e Row 1 passed to this class, internally means Row 0
  
    def initialize()
      @book = nil
      # The @patriarchs hash is a workaround because HSSFSheet.getDrawingPatriarch()
      # causes a lot of issues (if it doesn't throw an exception!)
      @patriarchs = Hash.new
      
      @date_style = nil
    end
  
    def open(filename)
      inp = FileInputStream.new(filename)

      @book = HSSFWorkbook.new(inp)
      
      @date_style = @book.createCellStyle
      @date_style.setDataFormat( JExcelFile::date_format )
      
      @current_sheet = 0
      sheet(@current_sheet)
    end
  
    # EXCEL ITEMS
    
    def create(sheet_name)
      @book = HSSFWorkbook.new() if @book.nil?

      acceptable_name = sheet_name.gsub(':', '').gsub(" ", '')
      
      # Double check sheet doesn't already exist
      if(@book.getSheetIndex(acceptable_name) < 0)
        sheet = @book.createSheet(acceptable_name.gsub(" ", ''))

        @patriarchs.store(acceptable_name, sheet.createDrawingPatriarch())
      end
      @current_sheet = @book.getSheetIndex(acceptable_name)
      
      @date_style = @book.createCellStyle
      @date_style.setDataFormat( JExcelFile::date_format )
      
      self.sheet()
    end

    alias_method(:create_sheet, :create)

    # Return the current or specified HSSFSheet
    def sheet(i = nil)
      @current_sheet = i if i
      @sheet = @book.getSheetAt(@current_sheet)
    end

    def activate_sheet(sheet)
      active_sheet = @current_sheet
      if(@book)
        i = sheet if sheet.kind_of?(Integer)
        i = @book.getSheetIndex(sheet) if sheet.kind_of?(String)

        if( i >= 0 )
          @book.setActiveSheet(i) unless @book.nil?
          active_sheet = @book.getSheetAt(i)
          active_sheet.setActive(true)
        end unless i.nil?
      end
      return active_sheet
    end
  
    def num_rows
      @sheet.getPhysicalNumberOfRows
    end

    # Process each row. (type is org.apache.poi.hssf.usermodel.HSSFRow)

    def each_row
      @sheet.rowIterator.each { |row| @row = row; yield row }
    end

    # Create new row, bring index in line with POI usage (our 1 is their 0)
    def create_row(index)
      return if @sheet.nil?
      raise "BAD INDEX: Row indexing starts at 1" if(index == 0)
      @row = @sheet.createRow(index - 1)
      @row
    end
    
    #############################
    # INSERTING DATA INTO EXCEL #
    #############################

    #  Populate a single cell with data
    #    
    def set_cell(row, column, datum)
      @row = @sheet.getRow(row - 1) || create_row(row)
      @row.createCell(column - 1, excel_cell_type(datum)).setCellValue(datum)
    end
    
    # Convert array into a header row
    def set_headers(headers)
      create_row(1)
      return if headers.empty?
    
      headers.each_with_index do |datum, i|
        @row.createCell(i, excel_cell_type(datum)).setCellValue(datum)
      end
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
  
    # Return a mapping from Ruby type to type for HSSFCell
    def excel_cell_type(data)
        
      if(data.kind_of?(Numeric))
        HSSFCell::CELL_TYPE_NUMERIC
      elsif(data.nil?)
        HSSFCell::CELL_TYPE_BLANK
      elsif(data.is_a?(TrueClass) || data.is_a?(FalseClass))
        HSSFCell::CELL_TYPE_BOOLEAN
      else
        HSSFCell::CELL_TYPE_STRING
      end
      # HSSFCell::CELL_TYPE_FORMULA
    end
    
    # TODO - Move into an ActiveRecord helper module of it's own
    def ar_to_headers( records )
      return if( !records.first.is_a?(ActiveRecord::Base) || records.empty?)
      
      headers = records.first.class.columns.collect( &:name )    
      set_headers( headers )
    end
        
    # Pass a set of AR records
    def ar_to_xls(records, options = {})
      return if( ! records.first.is_a?(ActiveRecord::Base) || records.empty?)
      
      row_index = 
        if(options[:no_headers])
        1
      else
        ar_to_headers( records )
        2
      end
      
      records.each do |record|
        create_row(row_index)
 
        ar_to_xls_row(1, record)
        
        row_index += 1
      end
    end
    
    # Save data from an AR record to the current row, based on the record's columns [c1,c2,c3]
    # Returns the number of the final column written to  
    def ar_to_xls_row(start_column, record)
      return unless( record.is_a?(ActiveRecord::Base))
        
      column = start_column
      record.class.columns.each do |connection_column|    
        ar_to_xls_cell(column, record, connection_column)
        column += 1
      end
      column
    end
    
    def ar_to_xls_cell(column, record, connection_column)  
      begin
        datum = record.send(connection_column.name)

        if(connection_column.sql_type =~ /date/) 
          @row.createCell(column - 1, HSSFCell::CELL_TYPE_STRING).setCellValue(datum.to_s) 
          
        elsif(connection_column.type == :boolean || connection_column.sql_type =~ /tinyint/) 
          @row.createCell(column - 1, HSSFCell::CELL_TYPE_BOOLEAN).setCellValue(datum) 
          
        elsif(connection_column.sql_type =~ /int/) 
          @row.createCell(column - 1, HSSFCell::CELL_TYPE_NUMERIC).setCellValue(datum.to_i)
        else
          @row.createCell(column - 1, HSSFCell::CELL_TYPE_STRING).setCellValue( datum.to_s ) 
        end
        
      rescue => e
        puts "Failed to export #{datum} from #{connection_column.inspect} to column #{column}"
        puts e
      end
    end
      
    ##############################
    # RETRIEVING DATA FROM EXCEL #
    ##############################

    # Return the raw data of the requested cell by row/column
    def get_cell_value(row, column)
      raise TypeError, "Expect row argument of type HSSFRow" unless row.is_a?(Java::OrgApachePoiHssfUsermodel::HSSFRow)
      cell_value( row.getCell(column) )
    end
  
    # Return the raw data of an HSSFCell
    def cell_value(cell)
      return unless cell
      #puts "DEBUG CELL TYPE : #{cell} => #{cell.getCellType().inspect}"
      case (cell.getCellType())
      when HSSFCell::CELL_TYPE_FORMULA  then return cell.getCellFormula()
      when HSSFCell::CELL_TYPE_NUMERIC  then return cell.getNumericCellValue()
      when HSSFCell::CELL_TYPE_STRING   then return cell.getStringCellValue()
      when HSSFCell::CELL_TYPE_BOOLEAN  then return cell.getBooleanCellValue()
      when HSSFCell::CELL_TYPE_BLANK    then return ""
      end
    end
    
    def save( filename = nil )
   
      filename.nil? ? file = @filepath : file = filename
      begin
        out = FileOutputStream.new(file)
        @book.write(out) unless @book.nil?

        out.close
      rescue => e
        puts e
        raise "Cannot write file - is file already open in Excel ?"
      end
    end

    def save_to_text( filename )
      File.open( filename, 'w') {|f| f.write(to_s) }
    end

        
    def add_comment( cell, text )
      raise "Please supply valid HSSFCell" unless cell.respond_to?('setCellComment')
      return if @sheet.nil?

      patriarch = @patriarchs[@sheet.getSheetName()]

      anchor = HSSFClientAnchor.new(100, 50, 100, 50, cell.getColumnIndex(), cell.getRowIndex(), cell.getColumnIndex()+3, cell.getRowIndex()+4)
      comment = patriarch.createCellComment(anchor)

      comment_text = HSSFRichTextString.new(text)
      comment.setString(comment_text)
      comment.setAuthor("Mapping")

      cell.setCellComment(comment)
    end

    # The internal representation of a Excel File
  
    # Get a percentage style
    def getPercentStyle()
      if (@percentCellStyle.nil? && @book)
        @percentCellStyle = @book.createCellStyle();
        @percentCellStyle.setDataFormat(HSSFDataFormat.getBuiltinFormat("0.00%"));
      end
      return @percentCellStyle
    end

    # Auto size either the given column index or all columns
    def autosize(column = nil)
      return if @sheet.nil?
      if (column.kind_of? Integer)
        @sheet.autoSizeColumn(column)
      else
        @sheet.getRow(0).cellIterator.each{|c| @sheet.autoSizeColumn(c.getColumnIndex)}
      end
    end

    def to_s
      return "" unless @book
            
      outs = ByteArrayOutputStream.new
      @book.write(outs);
      outs.close();
      String.from_java_bytes(outs.toByteArray)
    end

    def createFreezePane(row=1, column=0)
      return if @sheet.nil?
      @sheet.createFreezePane(row, column)
    end

    # Use execute to run sql query provided
    # and write to a csv file (path required)
    # header row is optional but default is on
    # Auto mapping of specified columns is optional
    # @mappings is a hash{column => map} of columns to a map{old_value => new_value}
    def results_to_sheet( results, sheet, mappings=nil, header=true)
      numrows = results.length
      sheet_name = sheet

      if (numrows == 0)
        log :info, "WARNING - results are empty nothing written to sheet: #{sheet}"
        return
      end

      #Check if we need to split the results into seperate sheets
      if (numrows > @@maxrows )
        startrow = 0
        while (numrows > 0)
          # Split the results and write to a new sheet
          next_results = results.slice(startrow, @@maxrows > numrows ? numrows : @@maxrows)
          self.results_to_sheet(next_results, "#{sheet_name}", mappings, header) if next_results

          # Increase counters
          numrows -= next_results.length
          startrow += next_results.length
          sheet_name += 'I'
        end
      else
        # Create required sheet
        self.create(sheet)

        row_index = self.num_rows
        # write header line
        if (header && row_index==0 )
          header_row = @sheet.createRow(row_index)
          cell_index = 0
          results[0].keys.each{ |h|
            header_row.createCell(cell_index).setCellValue("#{h}")
            @sheet.setDefaultColumnStyle(cell_index, self.getPercentStyle) if "#{h}".include? '%'
            cell_index += 1
          }
          # Freeze the header row
          @sheet.createFreezePane( 0, 1, 0, 1 )
          row_index += 1
        end

        # write_results
        results.each{ |row|
          sheet_row = @sheet.createRow(row_index)
          cell_index = 0
          row.each{|k,v|
            celltype = v.kind_of?(Numeric) ? HSSFCell::CELL_TYPE_NUMERIC : HSSFCell::CELL_TYPE_STRING
            cell = sheet_row.createCell(cell_index, celltype)

            v.nil? ? value = "<NIL>" : value = v

            cell.setCellValue(value)

            cell_index +=1
          }
          #puts "#{sheet}: written row #{row_index}"
          row_index +=1
        }
      end 
    
    end
    
  end   # END JExcelFile
else
  class JExcelFile
    def initialize
      raise DataShift::BadRuby, "Please install and use JRuby for working with .xls files"
    end
  end
end