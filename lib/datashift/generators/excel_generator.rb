# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Export a model to Excel '97(-2007) file format.
#
# TOD : Can we switch between .xls and XSSF (POI implementation of Excel 2007 OOXML (.xlsx) file format.)
#
#
require 'excel'

module DataShift

  class ExcelGenerator < GeneratorBase

    include DataShift::ExcelBase

    attr_accessor :excel
    attr_accessor :file_name

    def initialize
      super
    end

    # Create an Excel file template (header row) representing supplied Model
    # file_name => Filename for generated template
    #
    # See DataShift::Exporters::Configuration for options
    #
    def generate(file_name, klass, options = {})

      @file_name = file_name

      start_excel(klass, options)

      @headers = Headers.klass_to_headers(klass)

      @excel.set_headers(@headers)

      logger.info("ExcelGenerator saving generated template #{@file_name}")

      # @excel.autosize if(options[:autosize])

      @excel.write( @file_name )
    end

  end # ExcelGenerator

end # DataShift
