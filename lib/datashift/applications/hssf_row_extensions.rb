# Copyright:: Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     April 2016
# License::
#
if DataShift::Guards.jruby?

  # Extend the Poi classes with some syntactic sugar

  java_import 'org.apache.poi.ss.util.CellReference'

  module Java

    module OrgApachePoiHssfUsermodel

      # https://poi.apache.org/apidocs/org/apache/poi/ss/usermodel/Row.html
      class HSSFRow

        include RubyPoiTranslations

        include Enumerable

        def empty?
          getLastCellNum == -1
        end

        def size
          # Gets the number of defined cells (NOT number of cells in the actual row!).
          # That is to say if only columns 0,4,5 have values then there would be 3.
          getPhysicalNumberOfCells # or getLastCellNum ?
        end

        def []( column)
          cell_value( get_or_create_cell( column ) )
        end

        def []=( column, value )
          get_or_create_cell(column, value).setCellValue( poi_cell_value(value) )
        end

        def get_or_create_cell( column, value = nil )
          ref = CellReference.new(getRowNum, column)
          if value
            getCell(ref.getCol) # || createCell(column, poi_cell_type(value))
          else
            getCell(ref.getCol) # || java_send(:createCell, column)
          end
        end

        def idx
          getRowNum
        end

        # Iterate over each column in the row and yield on the cell
        def each(&_block)
          cellIterator.each { |c| yield cell_value(c) }
        end

        # TODO
        # for min, max and sort from enumerable need <=>
        # def <=> end

      end
    end
  end
end
