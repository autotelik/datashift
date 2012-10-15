# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'generator_base'

module DataShift

  class CsvGenerator < GeneratorBase

    def initialize(filename)
      super(filename)
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
