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
    # Options:
    #
    # * <tt>:title</tt> - Top level YAML node
    #
    # * <tt>:model_as_dest</tt> - Place model operators as the DESTINATION. Override default treatment using model for SOURCE
    #
    # Rails columns like id, created_at etc are added to the remove list by default
    #
    # * <tt>:include_rails</tt> - Specify to keep Rails columns in mappings
    #
    # * <tt>:associations</tt> - Additionally include all Associations
    #
    # * <tt>:exclude</tt> - Association TYPE(s) to exclude.
    #
    #     Possible association_type values are given by ModelMethod.supported_types_enum
    #       ... [:assignment, :belongs_to, :has_one, :has_many]
    #
    # * <tt>:file</tt> - Write mappings direct to file name provided
    #
    def generate(klass_or_name = nil, options = {})

      klass = klass_or_name.is_a?(String) ? MapperUtils.class_from_string_or_raise( klass_or_name ) : klass_or_name

      mappings = ''

      if(klass)

        mappings = options[:title] || "#{klass.name}:" + "\n"

        collection = ModelMethods::Manager.catalog_class(klass)

        prepare_model_headers(collection, options)

        if(options[:model_as_dest])
          headers.each_with_index { |s, i|  mappings += "       #srcs_column_heading_#{i}: #{s}\n" }
        else
          headers.each_with_index { |s, i|  mappings += "       #{s}: #dest_column_heading_#{i}\n" }
        end
      else

        mappings = options[:title] || MappingGenerator.title
        mappings += <<EOS
    # source_column_heading_0: dest_column_heading_0
    # source_column_heading_1: dest_column_heading_1
    # source_column_heading_2: dest_column_heading_2

EOS
      end

      if(options[:file])
        logger.info("Generating Mapping File [#{options[:file]}]")

        File.open(options[:file], 'w')  { |f| f << mappings  }
      end

      mappings

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

      if(options[:model_as_dest])
        headers.each_with_index { |s, i|  mappings += "       #srcs_column_heading_#{i}: #{s}\n" }
      else
        headers.each_with_index { |s, i|  mappings += "       #{s}: #dest_column_heading_#{i}\n" }
      end

      File.open(options[:file], 'w')  { |f| f << mappings  } if(options[:file])

      mappings

    end

  end

end # DataShift
