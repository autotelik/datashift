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
if(DataShift::Guards::jruby?)
  
  require 'java'
  
  require 'excel_base'
  require 'ruby_poi_translations'
  
  class JExcelFile
    
    include ExcelBase
    
    include RubyPoiTranslations
    extend RubyPoiTranslations
        
    include Enumerable
    
    include_class 'org.apache.poi.hssf.util.HSSFColor'
    java_import 'org.apache.poi.poifs.filesystem.POIFSFileSystem'

    java_import 'org.apache.poi.hssf.usermodel.HSSFCell'
    java_import 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
    java_import 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
    java_import 'org.apache.poi.hssf.usermodel.HSSFDataFormat'
    java_import 'org.apache.poi.hssf.usermodel.HSSFClientAnchor'
    java_import 'org.apache.poi.hssf.usermodel.HSSFRichTextString'

    attr_accessor :workbook, :row, :date_style
    attr_reader   :sheet, :current_sheet_index

    # NOTE: this is the POI 3.7 HSSF maximum rows
    @@maxrows = 65535

    def self.maxrows
      return @@maxrows
    end
  
    def self.date_format
      HSSFDataFormat.getBuiltinFormat("m/d/yy h:mm")
    end
    
    def self.open(filename)
      HSSFWorkbook.new(FileInputStream.new(filename))
    end
    
    # NOTES :
    #   The HSSFWorkbook uses 0 based indexes
  
    def initialize()
      @workbook = HSSFWorkbook.new
      
      @sheet = nil
      @current_sheet_index = 0
      
      # The @patriarchs hash is a workaround because HSSFSheet.getDrawingPatriarch()
      # causes a lot of issues (if it doesn't throw an exception!)
      @patriarchs = Hash.new
      
      @date_style = nil
    end
   
    def open(filename)
      @workbook = JExcelFile.open(filename)
      
      @date_style = @workbook.createCellStyle
      @date_style.setDataFormat( JExcelFile::date_format )
      
      activate_sheet(0)
      @workbook
    end
    
    # Create and return a new worksheet. 
    # Not set to the active worksheet
    
    def create_worksheet( options = {} )
      sheet_name = options[:name]
      
      @workbook = HSSFWorkbook.new() if @workbook.nil?
            
      unless(sheet_name)
        i = 0
        begin
          sheet_name = "Worksheet#{i += 1}"
        end while(@workbook.getSheetIndex(sheet_name) >= 0) # there is no hard limit to no of sheets in Excel but at some point you will run out of memory!
        
        return create_sheet_and_set_styles( sheet_name )
      else 
        
        name = sanitize_sheet_name( sheet_name )

        if (@workbook.getSheetIndex(name) < 0)  #Check sheet doesn't already exist
          return create_sheet_and_set_styles( name )
        else
          activate_sheet(name)
        end
      end
    end

    # Set the supplied sheet index or name, as the active sheet and return it.
    # If no such sheet return current sheet
    def activate_sheet(term)

      if(@workbook)
        x = term.is_a?(String) ? @workbook.getSheetIndex(term.to_java(java.lang.String)) : term
        @sheet = worksheet(x)
        
        if( @sheet )
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
      if(@workbook)
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
      raise "BAD INDEX: Row indexing starts at 0" if(index < 0)
      @row = @sheet.createRow(index)
      @row
    end
    
    def num_rows
      @sheet.getPhysicalNumberOfRows
    end

    # Process each row. Row type is org.apache.poi.hssf.usermodel.HSSFRow
        
    # Currently ignores skip argument - TODO - this is how spreadsheet gem works
    # #each iterates over all used Rows (from the first used Row until but omitting the first unused Row, see also #dimensions)
    # If the argument skip is given, 
    # #each iterates from that row until but omitting the first unused Row, effectively skipping the first skip Rows from the top of the Worksheet. 

    def each(skip = nil, &block) 
      @sheet.rowIterator.each(&block)
    end

    def row( index )
      @sheet.getRow(index) || create_row(index)
    end
         
    # Get the enriched value of the Cell at row, column.
    def cell(row, column) 
      row = row(row)
      cell_value( row.get_or_create_cell( column )  )
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
    
    def write( filename = nil )
      filename.nil? ? file = @filepath : file = filename
      out = FileOutputStream.new(file)
      @workbook.write(out) unless @workbook.nil?
      out.close
    end

    alias_method :save, :write
    
    def save_to_text( filename )
      File.open( filename, 'w') {|f| f.write(to_s) }
    end

    def to_s
      outs = ByteArrayOutputStream.new
      @workbook.write(outs);
      outs.close();
      String.from_java_bytes(outs.toByteArray)
    end
    
    private
       
    def create_sheet_and_set_styles( sheet_name )
      
      name = sanitize_sheet_name(sheet_name)
      
      @sheet = @workbook.createSheet( name )

      @patriarchs.store(name, @sheet.createDrawingPatriarch())
     
      @date_style = @workbook.createCellStyle
      @date_style.setDataFormat( JExcelFile::date_format )
      @sheet
    end
    
  end
  
  require 'jexcel_file_extensions'
  require 'apache_poi_extensions'
  
end