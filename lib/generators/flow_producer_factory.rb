# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Mar 2015
# License::   MIT
#
# Details::   Create a DataFlowSchema for use in import or export.
#
#             A DataFlowSchema directs the import or export of data by providing details of the required flow.

#             A Flow is direction agnostic, and contains a series of nodes (columns)
#             Each node includes details of the header and the operator required to get the data
#             for that column.
#
#             Importers and exporters can iterate through the series to generate output, or load data
#
#             The Flow can be defined by the user in a flow mapping YAML document
#
require 'generator_base'

module DataShift

  class FlowProducerFactory < GeneratorBase

    attr_accessor :template

    def initialize
      @template = MappingTemplate.new
    end

    def read( file, key = nil )

      @map_file_name = file

      unless map_file_name && File.exist?(map_file_name)
        logger.error "Cannot open mapping file - #{map_file_name} - file does not exist."
        raise FileNotFound, "Cannot open mapping file - #{map_file_name}"
      end

      begin
        # Load application configuration
        mapping_from(map_file_name )

        set_key_config!( key ) if key
      rescue => e
        logger.error e.inspect
        logger.error "Failed to parse config file #{map_file_name} - bad YAML ?"
        raise e
      end
    end

  end

end
