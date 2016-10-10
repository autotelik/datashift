# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Mar 2016
# License::   MIT.
#
require 'thor'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

  class Import < Thor

    include DataShift::Logging

    desc "load", "Import data from file for specific active record model"

    method_option :model, aliases: '-m', required: true, desc: 'The related active record model'

    method_option :input, aliases: '-i', required: true, desc: 'The input file'

    method_option :loader, aliases: '-l', required: false, desc: 'Loader class to use'

    method_option :verbose, aliases: '-v', type: :boolean, desc: 'Verbose logging'

    method_option :config, aliases: '-c', desc: 'YAML config file with defaults, over-rides etc'

    def load()
      start_connections

      importer = if(options[:loader])
                   logger.info("Attempting to use supplied Loader : #{options[:loader]}")
                   DataShift::MapperUtils::class_from_string(options[:loader]).new
                 else
                   logger.info("No Loader specified - finding appropriate Loader for file type")
                   DataShift::Loader::Factory.get_loader(options[:input])
                 end

      import(importer)
    end


    desc "excel", "Import .xls file for specifiec active record model"

    method_option :model, aliases: '-m', required: true, desc: 'The related active record model'

    method_option :input, aliases: '-i', required: true, desc: 'The input file'

    method_option :loader, aliases: '-l', required: false, desc: 'Loader class to use'

    method_option :verbose, aliases: '-v', type: :boolean, desc: 'Verbose logging'

    method_option :config, aliases: '-c', desc: 'YAML config file with defaults, over-rides etc'

    def excel()

      start_connections

      importer = if(options[:loader])
                   logger.info("Attempting to use supplied Loader : #{options[:loader]}")
                   DataShift::MapperUtils::class_from_string(options[:loader]).new
                 else
                   logger.info("No Loader specified - using standard Excel Loader")
                   DataShift::ExcelLoader.new
                 end

      import(importer)
    end

    desc "csv", "Import CSV file for specified active record model"

    method_option :model, aliases: '-m', required: true, desc: 'The related active record model'

    method_option :input, aliases: '-i', required: true, desc: 'The input file'

    method_option :loader, aliases: '-l', required: false, desc: 'Loader class to use'

    method_option :verbose, aliases: '-v', type: :boolean, desc: 'Verbose logging'

    method_option :config, aliases: '-c', desc: 'YAML config file with defaults, over-rides etc'

    def csv()

      start_connections

      importer = if(options[:loader])
                   logger.info("Attempting to use supplied Loader : #{options[:loader]}")
                   DataShift::MapperUtils::class_from_string(options[:loader]).new
                 else
                   logger.info("No Loader specified - using standard Csv Loader")
                   DataShift::CsvLoader.new
                 end

      import(importer)
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

      def import(importer)
        logger.info "Datashift: Starting Import from #{options[:input]}"

        importer.configure_from( options[:config] ) if(options[:config])

        importer.run(options[:input], options[:model])
      end
    end

  end
end
