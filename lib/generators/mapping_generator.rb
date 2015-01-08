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

    def initialize(filename)
      super(filename)
    end

    # Create an YAML template for mapping headers
    # Options:
    ## * <tt>:name</tt> - Title for the mapping else left as  ##enter_name
    # * <tt>:exclude</tt> - Array of headers to remove
    # * <tt>:model_as_dest</tt> - Override default treatment of using model as the SOURCE

    def generate(model = nil, options = {})

      #name = options[:name] || '##enter_name'

      File.open(filename, 'w')  do |f|

        mapping=<<EOS
mappings:
EOS
        if(model)

          klass = DataShift::ModelMapper.class_from_string_or_raise( model )

          MethodDictionary.find_operators( klass )

          MethodDictionary.build_method_details( klass )

          puts "TS DEBUG klass :#{klass.inspect}"

          @headers = MethodDictionary.assignments[klass]

          puts "TS DEBUG headers :#{headers.inspect}"

          remove_headers(options)

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

  end

end # DataShift