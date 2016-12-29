# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Module for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with Binder classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
module DataShift

  module Loader

    class Factory

      # Based on file_name find appropriate Loader

      # Currently supports :
      #   Excel/Open Office files saved as .xls
      #   CSV files
      #
      def self.get_loader(file_name)

        raise DataShift::BadFile, "Cannot load #{file_name} file not found." unless File.exist?(file_name)

        ext = File.extname(file_name)

        if ext.casecmp('.xls') == 0 || ext.casecmp('.xlsx') == 0
          return ExcelLoader.new
        elsif ext.casecmp('.csv') == 0
          return CsvLoader.new
        else
          raise DataShift::UnsupportedFileType, "#{ext} files not supported - Try .csv or OpenOffice/Excel .xls"
        end
      end

    end
  end
end
