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

module Spreadsheet

  class Worksheet

    include DataShift::ExcelBase

    # Convert array into a header row
    def set_headers(headers, _apply_style = nil)
      return if headers.empty?

      headers.each_with_index do |header, i|
        self[0, i] = header.to_s
      end
    end

    def num_rows
      rows.size
    end

  end
end
