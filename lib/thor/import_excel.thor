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
#  Requires Jruby, cmd Line:
#
# => bundle exec thor datashift:import:excel -m <active record class> -r <output_template.xls> -a
#
#  Cmd Line:
#
# => jruby -S rake datashift:import:excel model=<active record class> input=<file.xls>
# => jruby -S rake datashift:import:excel model=<active record class> input=C:\MyProducts.xlsverbose=true
#
require 'datashift'
  

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

          
  class Import < Thor     
  
    include DataShift::Logging
      
    desc "excel", "import .xls file for specifiec active record model" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The related active record model"
    method_option :inout, :aliases => '-r', :required => true, :desc => "The input .xls file"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include any associations supplied in the input"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    
    def excel()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'excel_loader'

      model = options[:model]
      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError
        raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
      end

      if(ENV['loader'])
        begin
          #loader_klass = Kernel.const_get(ENV['loader'])
          # support modules e.g "Spree::Property") 
          loader_klass = ModelMapper::class_from_string(ENV['loader'])  #Kernel.const_get(model)

          loader = loader_klass.new(klass)

          logger.info("INFO: Using loader : #{loader.class}")
        rescue
          logger.error("INFO: No specific #{model}Loader found  - using generic ExcelLoader")
          loader = DataShift::ExcelLoader.new(klass)
        end
      else
        logger.info("No Loader specified - using generic ExcelLoader")
        loader = DataShift::ExcelLoader.new(klass)
      end

      logger.info("ARGS #{options.inspect} [#{options[:verbose]}]")
      loader.logger.verbose if(ENV['verbose'])
      
      loader.configure_from( ENV['config'] ) if(ENV['config'])
       
      loader.perform_load(options[:input])
    end
  end

end

