# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  File based generators
#
require 'generator_base'

module DataShift

  class FileGenerator < DataShift::GeneratorBase

    attr_accessor :filename

    def initialize( filename )
      @filename = filename
      # .. this had me banging my head for a while ...
      # super without arguments is a shortcut for **passing the same arguments**
      # that were passed into the current method. Use () to explicitly pass 0 args
      super()
    end

    protected

    def prepare_excel(klass, options = {})
      @filename = options[:filename] if options[:filename]

      excel = DataShift::Excel.new

      name = options[:sheet_name] ? options[:sheet_name] : klass.name

      sheet = excel.create_worksheet( name: name )

      unless sheet
        logger.error("Excel failed to create WorkSheet called [#{name}]")

        raise "Failed to create Excel WorkSheet called [#{name}]"
      end

      excel
    end

  end

end
