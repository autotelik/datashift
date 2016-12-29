# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Export a model definition to CSV
#
#
module DataShift

  class CsvGenerator < GeneratorBase

    attr_accessor :file_name

    def initialize
      super
    end

    # Create CSV file representing supplied Model
    #
    def generate(file_name, klass)
      @file_name = file_name

      headers = Headers.klass_to_headers(klass)

      logger.info("CSVGenerator saving generated Template #{@file_name}")

      csv_delim = DataShift::Exporters::Configuration.call.csv_delimiter

      CSV.open(file_name, 'w', col_sep: csv_delim ) do |csv|
        csv << headers.sources
      end

    end

  end
end
