# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Read mappings and provide cache type services for source=>destination mappings
#
require 'erubis'

module DataShift

  class MappingServices

    include DataShift::Logging

    # N.B @mappings is an OpenStruct data structure
    #
    # Provides definition of config entries as attributes with their accompanying values.
    #
    # So if you had a top level config entries in the YAML called path & full_name, you can call
    #   mapping_service.path
    #   config.full_name etc
    #
    # For a more Hash like representation use config.yaml or config[:attribute]

    attr_reader :mapped_class_name, :map_file_name

    # As read from the mapping file
    attr_reader :raw_data, :yaml_data

    attr_reader :mappings

    def initialize( klass )
      @mapped_class_name = klass.name

      @mappings = OpenStruct.new
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

    # OpenStruct not a hash .. supports form ... config.path, config.full_name etc
    def method_missing(method, *_args, &_block
                      )
      puts "Call mapping data #{method.inspect}"
      # logger :debug, "method_missing called with : #{method}"
      @mappings.send(method)
    end

    private

    def mapping_from(file )

      @raw_data = File.read(file)

      erb = begin
        Erubis::Eruby.new(raw_data).result
      rescue => e
        logger.error "Failed to parse erb template #{file} "
        logger.error "template error: #{e.inspect}"
        raise e
      end

      begin
        @yaml_data = YAML.load(erb)

        puts "Loaded YAML #{@yaml_data.inspect}"

        logger.info "Loaded YAML config from [#{file}]"

      rescue => e
        logger.error "YAML parse error: #{e.inspect}"
        raise e
      end

      puts "Read mapping data #{yaml_data}"

      @mappings = OpenStruct.new(yaml_data)
    end

  end

end
