# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::
#
# Details::   A wrapper around creating and directly manipulating Excel files.
#             Acts as proxy over main Ruby gem spreadsheet and our own JRuby only implementation using Apache POI
#             Aim is to make it seamless to switch between any Excel implementation
#
#             http://spreadsheet.rubyforge.org/GUIDE_txt.html
#
require 'guards'

if DataShift::Guards.jruby?
  require 'jexcel_file'
else
  require 'spreadsheet'
  require 'spreadsheet_extensions'
end

module DataShift
  module ExcelProxy
    # Returns the current proxy class
    def self.proxy_class
      if DataShift::Guards.jruby?
        JExcelFile
      else
        Spreadsheet
      end
    end

    def self.proxy_object
      if DataShift::Guards.jruby?
        ExcelProxy.proxy_class.new
      else
        ExcelProxy.proxy_class::Workbook.new
      end
    end
  end

  class Excel # < BasicObject

    def initialize
      @excel_class = ExcelProxy.proxy_class
      @excel = ExcelProxy.proxy_object
    end

    # Forward all undefined methods to the wrapped Excel object.
    def method_missing(method, *args, &block)
      # puts @excel.class, method, args.inspect

      if @excel.respond_to?(method)
        @excel.send(method, *args, &block)
      elsif @excel.worksheets.last.respond_to?(method) # active_worksheet doesn't work so use the latest
        @excel.worksheets.last.send(method, *args, &block)
      elsif @excel_class.respond_to?(method)
        if method == :open || method == 'open'
          @excel = @excel_class.send(method, *args, &block)
        else
          @excel_class.send(method, *args, &block)
        end
      else
        super
      end
    end

    def self.method_missing(method, *args, &block)
      @excel_class.send(method, *args, &block)
    end

    # Returns +true+ if _obj_ responds to the given method. Private methods are included in the search
    # only if the optional second parameter evaluates to +true+.
    def respond_to?(method, include_private = false)
      super || @excel.respond_to?(method, include_private)
    end

    # without this can't get at any defined modules etc
    #
    def self.const_missing(name)
      ::Object.const_get(name)
    end

  end

end
