# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Create mappings between systems
#
require 'generator_base'

module DataShift

  class MappingGenerator < GeneratorBase

    include DataShift::Logging
    include ExcelBase

    def initialize(filename)
      super(filename)
    end

    # Create an YAML template for mapping headers
    #
    # Options:
    #
    # * <tt>:model_as_dest</tt> - Override default treatment of using model as the SOURCE
    #
    # * <tt>:remove</tt> - Array of header names to remove
    #
    # Rails columns like id, created_at etc are added to the remove list by default
    #
    # * <tt>:include_rails</tt> - Specify to keep Rails columns in mappings
    #
    # * <tt>:associations</tt> - Additionally include all Associations
    #
    # * <tt>:exclude</tt> - Association TYPE(s) to exclude.
    #
    #     Possible association_type values are given by MethodDetail::supported_types_enum
    #       ... [:assignment, :belongs_to, :has_one, :has_many]
    #
    # * <tt>:file</tt> - Write mappings direct to file name provided
    #
    def generate(model = nil, options = {})

      mappings = "mappings:\n"

      if(model)

        klass = DataShift::ModelMapper.class_from_string_or_raise( model )

        MethodDictionary.find_operators( klass )

        MethodDictionary.build_method_details( klass )

        prepare_model_headers(MethodDictionary.method_details_mgrs[klass], options)

        if(options[:model_as_dest])
          headers.each_with_index do |s, i|  mappings += "       #srcs_column_heading_#{i}: #{s}\n" end
        else
          headers.each_with_index do |s, i|  mappings += "       #{s}: #dest_column_heading_#{i}\n" end
        end
      else
        mappings += <<EOS
    ##source_column_heading_0: #dest_column_heading_0
    ##source_column_heading_1: #dest_column_heading_1
    ##source_column_heading_2: #dest_column_heading_2

EOS
      end

      File.open(options[:file], 'w')  do |f| f << mappings  end if(options[:file])

      mappings

    end

    # Create an YAML template from a Excel spreadsheet for mapping headers
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

      parse_headers(sheet, options[:header_row])

      mappings = "mappings:\n"

      if(options[:model_as_dest])
        excel_headers.each_with_index do |s, i|  mappings += "       #srcs_column_heading_#{i}: #{s}\n" end
      else
        excel_headers.each_with_index do |s, i|  mappings += "       #{s}: #dest_column_heading_#{i}\n" end
      end

      File.open(options[:file], 'w')  do |f| f << mappings  end if(options[:file])

      mappings

    end

  end

end # DataShift