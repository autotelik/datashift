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
require 'thor_base'


require 'datashift'

# Note, for thor not DataShift, case sensitive, want namespace for cmd line to be : datashift
module Datashift

          
  class Export < DataShift::DSThorBase

    desc "excel", "export any active record model (with optional associations)" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include all associations in the template"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    
    def excel()

      start_connections

      require 'excel_exporter'

      model = options[:model]
      result = options[:result]
     
      logger.info "Datashift: Start Excel export to #{result}"
            
      klass = DataShift::ModelMapper::class_from_string(model)  #Kernel.const_get(model)
    
      raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>" if(klass.nil?)

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
    method_option :methods, :aliases => '-c',  :type => :array, :desc => "List of additional methods to call on model, useful for situations like delegated methods"
    
    def csv()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'csv_exporter'

      model = options[:model]
      result = options[:result]
     
      logger.info "Datashift: Start CSV export to #{result}"
            
      klass = DataShift::ModelMapper::class_from_string(model)  #Kernel.const_get(model)
    
      raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>" if(klass.nil?)

      begin
        gen = DataShift::CsvExporter.new(result)

        if(options[:assoc])
          logger.info("Datashift: Exporting with associations")
          gen.export_with_associations(klass, klass.all, options)
        else
          gen.export(klass.all, options)
        end
      rescue => e
        puts e
        puts e.backtrace
        puts "Warning: Error during export, data may be incomplete"
      end

    end
    
    desc "db", "Export every Active Record model" 

    method_option :result, :aliases => '-r', :required => true, :desc => "Path in which to create excel files"
    method_option :csv, :aliases => '-c', :desc => "Export to CSV instead - Excel is default."
    method_option :prefix, :aliases => '-p', :desc => "For namespaced tables/models specify the table prefix e.g spree_"
    method_option :module, :aliases => '-m', :desc => "For namespaced tables/models specify the Module name e.g Spree"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include all associations in the template"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
 
    def db()
     
      require File.expand_path('config/environment.rb')
      
      require 'excel_exporter'
      require 'csv_exporter'
        
      exporter = options[:csv] ?  DataShift::CsvExporter.new(nil) :  DataShift::ExcelExporter.new(nil)
      
      ext = options[:csv] ? '.csv' : '.xls'
      
      # Hmmm not many models appear - Rails uses autoload !
      #ActiveRecord::Base.send(:subclasses).each do |model|
       # puts model.name
      #end
       
      parent = options[:module] ? Object.const_get(options[:module]) : Object
      
      ActiveRecord::Base.connection.tables.each do |table|
            
        table.sub!(options[:prefix],'') if(options[:prefix])

        @result = File.join(options[:result], "#{table}#{ext}")
        
        begin      
          @klass = parent.const_get(table.classify)    
        rescue => e
          puts e.inspect
          puts "WARNING: Could not find an AR model for Table #{table}"
          next
        end

        puts "Datashift: Start export to #{@result}"
         
        exporter.filename = @result
        
        raise "ERROR: No such Model [#{@klass}] found - check valid model supplied via -model <Class>" if(@klass.nil?)

        begin
          
          if(options[:assoc])
            opts = (options[:exclude]) ? {:exclude => options[:exclude]} : {}
            logger.info("Datashift: Exporting with associations")
            exporter.export_with_associations(@klass, @klass.all, opts)
          else
            exporter.export(@klass.all, :sheet_name => @klass.name)
          end
        rescue => e
          puts e
          puts e.backtrace
          puts "Warning: Error during export, data may be incomplete"
        end
      end
    end
    
  end

end
