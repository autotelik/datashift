# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'exporter_base'

module DataShift

  class CsvExporter < ExporterBase

    attr_accessor :excel, :filename
  
    def initialize(filename)
      @excel = nil
      @filename = filename
    end

    # Create CSV file representing supplied Model
    
    def generate(model, options = {})

      @filename = options[:filename] if  options[:filename]
    end

  
    # Create an Csv file representing supplied Model

    def export(items, options = {})
    end

  end
end
