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

    desc "load", "import data from file for specific active record model"
    method_option :model, :aliases => '-m', :required => true, :desc => "The related active record model"
    method_option :input, :aliases => '-i', :required => true, :desc => "The input file"
    method_option :config, :aliases => '-c', :desc => "YAML config file with defaults, over-rides etc"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include any associations supplied in the input"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::ModelMethod.supported_types_enum.to_a.inspect}"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"

    def load()

      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app,
      require File.expand_path('config/environment.rb')

      model = options[:model]

      klass = DataShift::MapperUtils.class_from_string_or_raise( model )

      loader_options = { :instance_methods => true }

      if(options[:loader])
        begin

          loader_klass = DataShift::MapperUtils::class_from_string(options[:loader])

          loader = loader_klass.new(options[:input], loader_options)

          logger.info("Using loader : #{loader.class}")
        rescue => x
          logger.error("No Loader of Type [#{options[:loader]}] found - check params")
          raise x
        end
      else
        logger.info("No Loader specified - using generic ExcelLoader")
        loader = DataShift::Loader::Factory.get_loader(options[:input], loader_options) #klass, nil, loader_options)
      end

      #TOFIX - multi loggers to file + STDOUT
      # loader.logger.verbose if(options['verbose'])

      loader.configure_from( options[:config] ) if(options[:config])

      loader.run(klass)
    end


    desc "excel", "import .xls file for specifiec active record model" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The related active record model"
    method_option :input, :aliases => '-i', :required => true, :desc => "The input .xls file"


    def excel()

      start_connections

      require 'excel_loader'

      model = options[:model]

      logger.info("Start Excel based import from model #{model}")

      klass = DataShift::MapperUtils.class_from_string_or_raise( model )

      loader_klass = if(options[:loader])
        begin
           DataShift::MapperUtils::class_from_string(options[:loader])

           logger.info("Using specified Loader : #{options[:loader]}")
        rescue
         raise NoSuchClassError("INFO: No such Loader [#{options[:loader]}] found ")
        end
      else
        logger.info("No Loader specified - using standard Excel Loader")
        DataShift::ExcelLoader
      end

      loader_options = { instance_methods: true, verbose: options[:verbose] }

      loader = loader_klass.new

      loader.configure_from( options[:config] ) if(options[:config])

      loader.run(options[:input], klass, loader_options)
    end
    
    desc "csv", "import CSV file for specified active record model" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The related active record model"
    method_option :input, :aliases => '-i', :required => true, :desc => "The input .xls file"
    method_option :config, :aliases => '-c', :desc => "YAML config file with defaults, over-rides etc"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include any associations supplied in the input"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::ModelMethod.supported_types_enum.to_a.inspect}"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"

    def csv()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'csv_loader'

      model = options[:model]

      klass = DataShift::MapperUtils.class_from_string_or_raise( model )

      loader = DataShift::CsvLoader.new

      loader_options = { instance_methods: true, verbose: options[:verbose] }
      
      loader.configure_from( options[:config] ) if(options[:config])

      loader.run(options[:input], klass, loader_options)
    end
    
  end

end

