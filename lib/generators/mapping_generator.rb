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
    def generate(model = nil, options = {})

      File.open(filename, 'w')  do |f|

        mapping=<<EOS
mappings:
EOS
        if(model)

          klass = DataShift::ModelMapper.class_from_string_or_raise( model )

          MethodDictionary.find_operators( klass )

          MethodDictionary.build_method_details( klass )

          prepare_model_headers(MethodDictionary.method_details_mgrs[klass], options)

          puts "TS DEBUG headers :#{headers.inspect}"

          if(options[:model_as_dest])
            headers.each_with_index do |s, i|  mapping += "       #srcs_column_heading_#{i}: #{s}\n" end
          else
            headers.each_with_index do |s, i|  mapping += "       #{s}: #dest_column_heading_#{i}\n" end
          end
        else
          mapping += <<EOS
    ##source_column_heading_0: #dest_column_heading_0
    ##source_column_heading_1: #dest_column_heading_1
    ##source_column_heading_2: #dest_column_heading_2

EOS
        end

        f << mapping
      end
    end

    # Create an YAML template from a Excel spreadsheet for mapping headers
    #
    # * <tt>:model_as_dest</tt> - Override default treatment of using model as the SOURCE
    #
    def generate_from_excel(excel_file_name, options = {})

      excel = Excel.new

      puts "\n\n\nGenerating mapping from Excel file: #{excel_file_name}"

      excel.open(excel_file_name)

      sheet_number = options[:sheet_number] || 0

      sheet = excel.worksheet( sheet_number )

      parse_headers(sheet, options[:header_row])

      mapping = "mappings:\n"

      puts "TS DEBUG headers :#{headers.inspect}"

      if(options[:model_as_dest])
        excel_headers.each_with_index do |s, i|  mapping += "       #srcs_column_heading_#{i}: #{s}\n" end
      else
        excel_headers.each_with_index do |s, i|  mapping += "       #{s}: #dest_column_heading_#{i}\n" end
      end

      puts mapping

      File.open(filename, 'w')  do |f| f << mapping  end

    end

  end

end # DataShift