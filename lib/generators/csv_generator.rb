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
    # Options
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    # [:file_name] => Filename for generated template
    #
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def generate(file_name, klass, options = {})
      @file_name = file_name

      klass_to_headers(klass, options)

      logger.info("CSVGenerator saving generated Template #{@file_name}")

      CSV.open(@file_name, 'w') do |csv|
        csv << headers
      end

    end

    # Create CSV file representing supplied Model
    #
    #  file_name => Filename for generated template
    #
    # Options
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    #   Otherwise, defaults to including all association types defined by
    #   ModelMethod.supported_types_enum - which can be further refined by
    #
    # [:exclude] => List of association Types to include (:has_one etc)
    #
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def generate_with_associations(file_name, klass, options = {})
      @file_name = file_name

      generate(file_name, klass, options)
    end

  end
end
