# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Mar 2012
# License::   MIT.
#
# Usage::
#
#  To pull Datashift commands into your main application :
#
#     require 'datashift'
#
#     DataShift::load_commands
#
#  N.B Requires JRuby
#
# => bundle exec thor datashift:import:excel -m <active record class> -i <output_template.xls> -a
#

require 'datashift'
  

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

          
  class Import < Thor     
  
    include DataShift::Logging
      
    desc "excel", "import .xls file for specifiec active record model" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The related active record model"
    method_option :input, :aliases => '-i', :required => true, :desc => "The input .xls file"
    method_option :config, :aliases => '-c', :desc => "YAML config file with defaults, over-rides etc"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include any associations supplied in the input"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"
     
    def excel()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'excel_loader'

      model = options[:model]

      klass = DataShift::ModelMapper.class_from_string_or_raise( model )

      if(options[:loader])
        begin
     
          loader_klass = DataShift::ModelMapper::class_from_string(options[:loader])

          loader = loader_klass.new(klass)

          logger.info("INFO: Using loader : #{loader.class}")
        rescue
          logger.error("INFO: No specific #{model}Loader found  - using generic ExcelLoader")
          loader = DataShift::ExcelLoader.new(klass, true)
        end
      else
        logger.info("No Loader specified - using generic ExcelLoader")
        loader = DataShift::ExcelLoader.new(klass, true)
      end

      logger.info("ARGS #{options.inspect}")
      loader.logger.verbose if(options['verbose'])
      
      loader.configure_from( options[:config] ) if(options[:config])


      loader.perform_load(options[:input])
    end
    
    desc "csv", "import CSV file for specified active record model" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The related active record model"
    method_option :input, :aliases => '-i', :required => true, :desc => "The input .xls file"
    method_option :config, :aliases => '-c', :desc => "YAML config file with defaults, over-rides etc"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include any associations supplied in the input"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"

    def csv()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'csv_loader'

      model = options[:model]

      klass = DataShift::ModelMapper.class_from_string_or_raise( model )

      loader = DataShift::CsvLoader.new(klass)
      
      loader.logger.verbose if(options['verbose'])
      
      loader.configure_from( options[:config] ) if(options[:config])

      loader.perform_load(options[:input])
    end
    
  end

end

