# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::   
#
#
# Extend the Sporeadsheet classes with some of our common methods
# 
# ... to do extract into separate module with pure ruby that works with both POI and Spreadsheet

require 'excel_base'
  
class Spreadsheet::Worksheet 
     
   include ExcelBase
    
  # Convert array into a header row
  def set_headers(headers, apply_style = nil)
    return if headers.empty?

    headers.each_with_index do |datum, i|
      self[0, i] = datum
    end
  end
  
  def num_rows
    rows.size
  end
  
end
  