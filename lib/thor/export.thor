# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     April 2012
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
#  Cmd Line:
#
# => bundle exec thor datashift:export:excel -m <active record class> -r <output_template.xls> -a
#
require 'datashift'
  
# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

          
  class Export < Thor     
  
    include DataShift::Logging
      
    desc "excel", "export any active record model (with optional associations)" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include all associations in the template"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    
    def excel()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'excel_exporter'

      model = options[:model]
      result = options[:result]
     
      logger.info "Datashift: Start Excel export to #{result}"
            
      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError => e
        puts e
        raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>"
      end

      begin
        gen = DataShift::ExcelExporter.new(result)

        if(options[:assoc])
          opts = (options[:exclude]) ? {:exclude => options[:exclude]} : {}
          logger.info("Datashift: Exporting with associations")
          gen.export_with_associations(klass, klass.all, opts)
        else
          gen.export(klass.all, :sheet_name => klass.name)
        end
      rescue => e
        puts e
        puts e.backtrace
        puts "Warning: Error during export, data may be incomplete"
      end

    end
  
    desc "csv", "export any active record model (with optional associations)" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include all associations in the template"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    
    def csv()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'csv_exporter'

      model = options[:model]
      result = options[:result]
     
      logger.info "Datashift: Start CSV export to #{result}"
            
      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError => e
        puts e
        raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>"
      end

      begin
        gen = DataShift::CsvExporter.new(result)

        if(options[:assoc])
          opts = (options[:exclude]) ? {:exclude => options[:exclude]} : {}
          logger.info("Datashift: Exporting with associations")
          gen.export_with_associations(klass, klass.all, opts)
        else
          gen.export(klass.all)
        end
      rescue => e
        puts e
        puts e.backtrace
        puts "Warning: Error during export, data may be incomplete"
      end

    end
  end

end
