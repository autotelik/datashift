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
require 'file_generator'

module DataShift

  class ExcelGenerator < FileGenerator

    include DataShift::Logging

    attr_accessor :excel

    def initialize(filename)
      super filename
    end

    # Create an Excel file template (header row) representing supplied Model
    # Options
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    # [:filename] => Filename for generated template
    #
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def generate(klass, options = {})

      @excel = prepare_excel(klass, options)

      @excel.set_headers( to_headers(klass, options) )

      logger.info("ExcelGenerator saving generated template #{@filename}")

      # @excel.autosize if(options[:autosize])

      @excel.write( @filename )
    end


  end # ExcelGenerator

end # DataShift
