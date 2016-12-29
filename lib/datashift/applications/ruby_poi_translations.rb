# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::
#
# Translate Apache Poi Java data types/va;pues to Ruby world
#
if DataShift::Guards.jruby?

  require 'java'

  require 'benchmark'
  require 'poi-3.7-20101029.jar'

  module RubyPoiTranslations

    java_import 'org.apache.poi.poifs.filesystem.POIFSFileSystem'

    java_import 'org.apache.poi.hssf.usermodel.HSSFCell'
    java_import 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
    java_import 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
    java_import 'org.apache.poi.hssf.usermodel.HSSFDataFormat'
    java_import 'org.apache.poi.hssf.usermodel.HSSFClientAnchor'
    java_import 'org.apache.poi.hssf.usermodel.HSSFRichTextString'

    java_import 'org.apache.poi.hssf.util.HSSFColor'

    java_import 'java.io.ByteArrayOutputStream'
    java_import 'java.util.Date'
    java_import 'java.io.FileInputStream'
    java_import 'java.io.FileOutputStream'

    # Cell.CELL_TYPE_NUMERIC, Cell.CELL_TYPE_STRING, Cell.CELL_TYPE_FORMULA,
    # Cell.CELL_TYPE_BLANK, Cell.CELL_TYPE_BOOLEAN, Cell.CELL_TYPE_ERROR

    def cell_value(cell)
      return '' unless(cell)

      case cell.getCellType
      when HSSFCell::CELL_TYPE_FORMULA  then return cell.getCellFormula
      when HSSFCell::CELL_TYPE_NUMERIC  then return cell.getNumericCellValue
      when HSSFCell::CELL_TYPE_STRING   then return cell.getStringCellValue
      when HSSFCell::CELL_TYPE_BOOLEAN  then return cell.getBooleanCellValue
      when HSSFCell::CELL_TYPE_ERROR    then return cell.getErrorCellValue

      when HSSFCell::CELL_TYPE_BLANK    then return ''
      end
    end

    # Cell.CELL_TYPE_NUMERIC, Cell.CELL_TYPE_STRING, Cell.CELL_TYPE_FORMULA,
    # Cell.CELL_TYPE_BLANK, Cell.CELL_TYPE_BOOLEAN, Cell.CELL_TYPE_ERROR

    # TODO: - properly
    def poi_cell_value(data)
      case data
      when BigDecimal
        data.to_f
      when Numeric, TrueClass, FalseClass
        data
      else
        data.to_s
      end
    end

    # Return the suitable type for a HSSFCell from a Ruby data type
    def poi_cell_type(data)

      if data.is_a?(Numeric)
        HSSFCell::CELL_TYPE_NUMERIC
      elsif data.nil?
        HSSFCell::CELL_TYPE_BLANK
      elsif data.is_a?(TrueClass) || data.is_a?(FalseClass)
        HSSFCell::CELL_TYPE_BOOLEAN
      else
        HSSFCell::CELL_TYPE_STRING
      end
      # HSSFCell::CELL_TYPE_FORMULA
    end
  end

end
