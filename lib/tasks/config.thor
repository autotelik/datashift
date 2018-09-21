# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Mar 2016
# License::   MIT.
#
#
require 'thor'
require_relative 'thor_behaviour'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

  module Config

    class Generate < Thor

      DEFAULT_IMPORT_TEMPLTE ||= 'import_mapping_template.yaml'.freeze

      include DataShift::ThorBehavior

      desc 'import', 'Generate an Import configuration template (YAML)'

      method_option :model, aliases: '-m', required: true, desc: 'The active record model to use for mappings'

      method_option :result, aliases: '-r', required: true,
                             desc: "Path or file to create resulting YAML config\n\nIf a PATH supplied, filename will be [#{DEFAULT_IMPORT_TEMPLTE}]"

      #   :remove_columns - List of columns to remove from files
      #
      #   :remove_rails - Remove standard Rails cols like :id, created_at etc

      def import

        start_connections

        result = options[:result]

        result = File.join(result, DEFAULT_IMPORT_TEMPLTE) if File.directory?(result)

        logger.info "Datashift: Starting Import mapping template generation to [#{result}]"

        mapper = DataShift::ConfigGenerator.new

        puts "Creating new configuration file : [#{result}]"
        begin
          mapper.write_import(result, options[:model], options)
        rescue StandardError => x
          puts "ERROR - Failed to create config file #{result}"
          puts x.message
        end

      end
    end

  end
end
