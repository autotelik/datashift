# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Mar 2016
# License::   MIT.
#
#
require 'thor'

# Note, not DataShift, case sensitive, create namespace for command line : datashift

module Datashift

  class Config < Thor

    DEFAULT_IMPORT_TEMPLTE ||= "import_mapping_template.yaml".freeze

    include DataShift::Logging

    desc "import", "Generate an Import configuration template (YAML)"

    method_option :model, aliases: '-m', required: true, desc: "The active record model to use for mappings"

    method_option :result, aliases: '-r', required: true,
                  desc: "Path or file to create resulting YAML config\nIf PATH, filename is [#{DEFAULT_IMPORT_TEMPLTE}]"

    def import()

      start_connections

      result = options[:result]

      if(File.directory?(result))
        result = File.join(result, DEFAULT_IMPORT_TEMPLTE)
      end

      logger.info "Datashift: Starting Import mapping template generation to [#{result}]"

      mapper = DataShift::ConfigGenerator.new

      puts "Creating new configuration file : [#{result}]"
      mapper.write_import(result, options[:model], options)

    end

    no_commands do

      def start_connections

        if File.exist?(File.expand_path('config/environment.rb'))
          begin
            require File.expand_path('config/environment.rb')
          rescue => e
            logger.error("Failed to initialise ActiveRecord : #{e.message}")
            raise ConnectionError.new("Failed to initialise ActiveRecord : #{e.message}")
          end

        else
          raise PathError.new('No config/environment.rb found - cannot initialise ActiveRecord')
        end
      end

    end

  end
end
