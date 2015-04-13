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

      # Based on filename find appropriate Loader

      # Currently supports :
      #   Excel/Open Office files saved as .xls
      #   CSV files
      #
      def get_loader(file_name, options = {} )

        raise DataShift::BadFile, "Cannot load #{file_name} file not found." unless(File.exist?(file_name))

        logger.info("Perform Load Options:\n#{options.inspect}")

        ext = File.extname(file_name)

        if(ext.casecmp('.xls') == 0 || ext.casecmp('.xlsx') == 0)
          return ExcelLoader.new(file_name, options )
        elsif(ext.casecmp('.csv') == 0)
          return CsvLoader.new(file_name, options)
        else
          raise DataShift::UnsupportedFileType, "#{ext} files not supported - Try .csv or OpenOffice/Excel .xls"
        end
      end

      # OPTIONS :
      #
      #  [:dummy]         : Perform a dummy run - attempt to load everything but then roll back
      #
      #  strict           : Raise an exception of any headers can't be mapped to an attribute/association
      #  ignore           : List of column headers to ignore when building operator map
      #  mandatory        : List of columns that must be present in headers
      #
      #  force_inclusion  : List of columns that do not map to any operator but should be includeed in processing.
      #                     This provides the opportunity for loaders to provide specific methods to handle these fields
      #                     when no direct operator is available on the model or it's associations
      #

    end
  end
end