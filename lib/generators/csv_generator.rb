# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Export a model to CSV
#
#
module DataShift

  class CsvGenerator < FileGenerator

    include DataShift::Logging

    def initialize
      super
    end

    # Create CSV file representing supplied Model
    #
    def generate(file_name, klass)
      @file_name = file_name

      klass_to_headers(klass)

      logger.info("CSVGenerator saving generated Template #{@file_name}")

      CSV.open(@file_name, 'w') do |csv|
        csv << headers
      end

    end

  end
end
