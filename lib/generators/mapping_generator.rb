# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Mar 2015
# License::   MIT
#
# Details::   Create mappings between systems
#
require 'generator_base'

module DataShift

  class MappingGenerator < GeneratorBase

    include DataShift::Logging
    include ExcelBase

    def self.title
      @mappings_title ||= "datashift_mappings:\n"
    end

    attr_accessor :output_filename

    def initialize
      super
    end

    # Create an YAML template for mapping headers
    #
    # For exportable options See DataShift::Exporters::Configuration
    #
    # Options:
    #
    # * <tt>:title</tt> - Top level YAML node
    #
    # * <tt>:model_as_dest</tt> - Place model operators as the DESTINATION.
    #                             Override default treatment using model for SOURCE
    #
    # * <tt>:file</tt> - Write mappings direct to file name provided
    #
    def generate(klass_or_name = nil, options = {})

      config = options.dup

      @klass = MapperUtils::ensure_class(klass_or_name)

      template =File.join(DataShift.library_path, 'datashift/templates/standard_mapping_transform.erb')

      @title = config[:title] || "#{@klass.name}"

      @defaults = []
      @overrides = []
      @substitutions = []
      @prefixs = []
      @postfixs = []

      klass_to_headers(@klass)

      result = Erubis::Eruby.new( File.read(template)).result(binding)

      puts result

      if config[:file]
        logger.info("Generating Mapping File [#{config[:file]}]")

        File.open(config[:file], 'w') { |f| f << result }
      end

    end

    # Create an YAML template from a Excel spreadsheet for mapping headers
    #
    #
    # * <tt>:title</tt> - Top level YAML node -defaults to MappingGenerator.title
    #
    # * <tt>:model_as_dest</tt> - Override default treatment of using model as the SOURCE
    #
    # * <tt>:file</tt> - Write mappings direct to file name provided
    #
    def generate_from_excel(excel_file_name, options = {})

      excel = Excel.new

      puts "\n\n\nGenerating mapping from Excel file: #{excel_file_name}"

      excel.open(excel_file_name)

      sheet_number = options[:sheet_number] || 0

      sheet = excel.worksheet( sheet_number )

      @headers = parse_headers(sheet, options[:header_row] || 0)

      mappings = options[:title] || MappingGenerator.title

      if options[:model_as_dest]
        headers.each_with_index { |s, i|  mappings += "       #srcs_column_heading_#{i}: #{s}\n" }
      else
        headers.each_with_index { |s, i|  mappings += "       #{s}: #dest_column_heading_#{i}\n" }
      end

      File.open(options[:file], 'w') { |f| f << mappings } if options[:file]

      mappings

    end

  end

end # DataShift
