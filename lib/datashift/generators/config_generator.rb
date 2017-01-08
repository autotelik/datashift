# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Mar 2015
# License::   MIT
#
# Details::   Generate an empty Configuration file, users can populate
#             to configure their specific import and export
#
require 'generator_base'

module DataShift

  class ConfigGenerator < GeneratorBase

    def self.title
      @mappings_title ||= "datashift_mappings:\n"
    end

    attr_accessor :output_filename, :headers

    attr_writer :import_template, :export_template

    def initialize
      super
    end

    def import_template
      @import_template ||= File.join(DataShift.library_path, 'datashift/templates/import_export_config.erb')
    end

    def export_template
      @export_template ||= File.join(DataShift.library_path, 'datashift/templates/import_export_config.erb')
    end

    # You can pass Transformations into the options
    #
    #     options[:defaults]
    #     options[:overrides]
    #     options[:substitutions]
    #     options[:prefixes]
    #     options[:postfixes]
    #
    # For example :
    #
    #   options = {
    #     defaults: {'value_as_string': 'some default text', 'value_as_double': 45.467 }
    #   }
    #
    def write_import(file_name, klass_or_name, options = {})
      result = create_import_config(klass_or_name, options)

      logger.info("Writing Import Config File [#{file_name}]")

      File.open(file_name, 'w') { |f| f << result }

      result
    end

    # N.B Gettign the YAML formatted correctly was nigh on impossible  in ERB,
    # be careful of the spacing in the string sections here e.g dont use IDE auto spacing tools

    # TODO: - How to better isolate these string template snippets

    # Create an YAML ERB Configuration template for Importing.
    # Includes available transformations and column mapping
    #
    # For other options See DataShift::Loaders::Configuration
    #
    def create_section(hash)
      section = ''
      (hash || { "#name": 'value' } ).each { |n, v| section += "        #{n}: #{v}\n" }
      section
    end

    # Includes a column mapping section, generated from klass_to_headers.
    #
    # The column set to be exported to the config file
    # can be manipulated via configuration options such as
    #
    #   :remove_columns - List of columns to remove from files
    #
    #   :remove_rails - Remove standard Rails cols like :id, created_at etc
    #
    def create_import_config(klass_or_name, options = {})

      klass = MapperUtils.ensure_class(klass_or_name)

      @key = 'data_flow_schema'
      @klass = klass.name.to_s

      defaults_section = create_section(options[:defaults] )
      overrides_section = create_section(options[:overrides] )
      prefixes_section = create_section(options[:prefixes] )
      postfixes_section = create_section(options[:postfixes] )

      @substitutions = options[:substitutions] || {}

      # operator => [rule , replacement]
      substitutions_section = ''

      @substitutions.each do |o, v|
        raise BadConfig, 'Substitutions need be in format {operator: [rule, replacement]}' unless(v.is_a? Array)
        substitutions_section += <<-EOS
        #{o}:
          - #{v.first}
          - #{v.last}
        EOS
      end

      @headers = Headers.klass_to_operators(klass)

      nodes_section = <<-EOS
    # Mappings between inbound column names and internal names
    # are only required when datashift cannot guess the mapping itself
    # It will automatically map headings like :
    #  'Product properties' or 'Product_Properties', 'product Properties' etc to product_properties
    nodes:
EOS

      @headers.each_with_index do |s, _i|
        nodes_section += <<-EOS
        - #{s}:
            heading:
               source: #{s}
        EOS
      end

      x = <<-EOS
# YAML Configuration file for Datashift Import/Export
#
#{@key}:
  #{@klass}:
    defaults:
#{defaults_section}
    overrides:
 #{overrides_section}
    # Expects a tuple (list with 2 entries), the rule and the replacement
    substitutions:
#{substitutions_section}
    prefixes:
#{prefixes_section}
    postfixes:
#{postfixes_section}

#{nodes_section}

      EOS

      # This was a nightmare to get proeprly formatted YAML
      # Erubis::Eruby.new( File.read(import_template)).result(binding)

      x
    end

    # FOR EXPORTERS

    def write_export(file_name, klass_or_name, options = {})
      result = export(klass_or_name, options)

      logger.info("Writing Export Config File [#{config[:file]}]")

      File.open(file_name, 'w') { |f| f << result }
    end

    # Create an YAML Configuration template for Exporting
    # includes available transformations and column mapping
    #
    # For other options See DataShift::Exporters::Configuration
    #
    def export(klass_or_name, options = {})

      @klass = MapperUtils.ensure_class(klass_or_name)

      @title = @klass.name.to_s

      @defaults = options[:defaults] || []

      @overrides = options[:overrides] || []
      @substitutions = options[:substitutions] || []
      @prefixs = options[:prefixs] || []
      @postfixs = options[:postfixs] || []

      klass_to_headers(@klass)

      Erubis::Eruby.new( File.read(export_template)).result(binding)
    end

    # Create an YAML template BAASED on an Excel spreadsheet for mapping headers
    #
    # * <tt>:title</tt> - Top level YAML node -defaults to ConfigGenerator.title
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

      @headers = excel.parse_headers(sheet, options[:header_row] || 0)

      mappings = options[:title] || ConfigGenerator.title

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
