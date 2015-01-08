# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   A cache type class that stores details of a source=>destination mapping
#
require 'erubis'

module DataShift

  class MappingService

    include DataShift::Logging

    # N.B :all_config, :key_config are OpenStruct data structure
    # that provides definition of config entries as attributes with their accompanying values.
    # So if you had a top level config entries in the YAML called path & full_name, you can call
    #   config.path
    #   config.full_name etc
    #
    # For a more Hash like representation use config.yaml or config[:attribute]

    attr_reader :mapped_class_name, :map_file_name

    attr_reader :raw_data, :yaml_data, :mapping_entry

    def initialize( klass )
      @mapped_class_name = klass.name
    end

    def read( file, key = nil )

      @map_file_name = file

      unless(map_file_name && File.exists?(map_file_name))
        logger.error "Cannot open mapping file - #{map_file_name} - file does not exist."
        raise FileNotFound.new("Cannot open mapping file - #{map_file_name}")
      end

      begin
        # Load application configuration
        set_mapping( map_file_name )

        set_key_config!( key ) if key
      rescue => e
        puts e.inspect
        logger.error "Failed to parse config file #{map_file_name} - bad YAML ?"
        raise e
      end
    end

    # OpenStruct not a hash .. supports form ... config.path, config.full_name etc
    def method_missing(method, *args, &block)
      #logger :debug, "method_missing called with : #{method}"
      @mapping_entry.send(method)
    end

    private

    def set_mapping( file )

      @raw_data = File.read(file)

      erb = begin
       Erubis::Eruby.new(raw_data).result
      rescue => e
        puts "Failed to parse erb template #{file} error: #{e.inspect}"

        logger.error "Config template error: #{e.inspect}"

        raise e
      end

      begin
        @yaml_data = YAML.load(erb)

        logger.info "Loaded YAML config from [#{file}]"

      rescue => e
        puts "YAML parse error: #{e.inspect}"
        logger.error "YAML parse error: #{e.inspect}"
        raise e
      end

      @mapping_entry = OpenStruct.new(yaml_data)
    end

end

end