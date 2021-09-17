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

    def initialize(config: nil)
      super(config: config)
    end

    # Create an Excel file template (header row) representing supplied Model
    # file_name => Filename for generated template
    #
    # See DataShift::Exporters::Configuration for options
    #
    def generate(file_name, klass, associations: false, options: {})

      raise DataProcessingError , "No file name supplied to ExcelGenerator" unless file_name.present?

      @file_name = file_name

      start_excel(klass, options)

      @config.with = :all if associations

      @headers = Headers.klass_to_headers(klass, config: config)

      options.fetch(:additional_headers, []).each {|h| @headers.prepend(h) }

      @excel.set_headers(@headers)

      logger.info("ExcelGenerator saving generated template #{@file_name}")

      # @excel.autosize if(options[:autosize])

      @excel.write( @file_name )
    end

  end # ExcelGenerator

end # DataShift
