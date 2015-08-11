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

    def initialize(filename)
      super filename
    end

    # Create CSV file representing supplied Model
    #
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
      @filename = options[:filename] if options[:filename]

      to_headers(klass, options)

      logger.info("CSVGenerator saving generated Template #{@filename}")

      CSV.open(@filename, 'w') do |csv|
        csv << headers
      end

    end


    # Create CSV file representing supplied Model
    #
    # Options
    #
    # [:filename] => Filename for generated template
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
    def generate_with_associations(klass, options = {})

      # For each type belongs has_one, has_many etc find the operators
      # and create headers, then for each record call those operators
      options[:with] = op_types_in_scope( options )

      generate(klass, options)
    end

  end
end
