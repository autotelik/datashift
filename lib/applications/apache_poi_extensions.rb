# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::   
#
#
if(DataShift::Guards::jruby?)
  
  require 'java'
  require "poi-3.7-20101029.jar"
      
  # Extend the Poi classes with some syntactic sugar
  
  class Java::OrgApachePoiHssfUsermodel::HSSFSheet
    def name() 
      getSheetName
    end
    
    def num_rows
      getPhysicalNumberOfRows
    end
  
  end
  
  class Java::OrgApachePoiHssfUsermodel::HSSFRow
    
    include RubyPoiTranslations
    
    include Enumerable
        
    def []( column)
      cell_value( get_or_create_cell( column )  )
    end
    
    def []=( column, value )
      get_or_create_cell(column, value).setCellValue( poi_cell_value(value) )
    end
  
    def get_or_create_cell( column, value = nil )
      if(value)
        java_send(:getCell, [Java::int], column) || createCell(column, poi_cell_type(value))
      else
        java_send(:getCell, [Java::int], column) || java_send(:createCell, [Java::int], column)
      end
    end
    
    def idx 
      getRowNum() 
    end
    
    # Iterate over each column in the row and yield on the cell
    def each(&block) 
      cellIterator.each {|c| yield cell_value(c) }        
    end
     
    # TODO
    # for min, max and sort from enumerable need <=>
   # def <=> end
     
  end
  
end