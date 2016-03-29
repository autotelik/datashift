# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Mar 2016
# License::   MIT.
#
require_relative 'thor_import_base'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

  class Import < DataShift::ThorImportBase

    include DataShift::Logging

    desc "load", "Import data from file for specific active record model"

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

      def import(importer)
        logger.info "Datashift: Starting Import from #{options[:input]}"

        importer.configure_from( options[:config] ) if(options[:config])

        importer.run(options[:input], options[:model])
      end

    end

  end
end