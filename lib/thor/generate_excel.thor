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
#  Cmd Line:
#
# => bundle exec thor datashift:generate:excel -m <active record class> -r <output_template.xls> -a
#
require 'datashift'
  
# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

          
  class Generate < Thor     
  
    include DataShift::Logging
      
    desc "excel", "generate a template from an active record model (with optional associations)" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"
    method_option :assoc, :aliases => '-a', :type => :boolean, :desc => "Include all associations in the template"
    method_option :exclude, :aliases => '-e',  :type => :array, :desc => "Use with -a : Exclude association types. Any from #{DataShift::MethodDetail::supported_types_enum.to_a.inspect}"
    
    def excel()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
   
      require 'excel_generator'

      model = options[:model]
      result = options[:result]
     
      logger.info "Datashift: Start Excel template generation in #{result}"
            
      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError => e
        puts e
        raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>"
      end

      begin
        gen = DataShift::ExcelGenerator.new(result)

        if(options[:assoc])
          opts = (options[:exclude]) ? {:exclude => options[:exclude]} : {}
          logger.info("Datashift: Generating with associations")
          gen.generate_with_associations(klass, opts)
        else
          gen.generate(klass)
        end
      rescue => e
        puts e
        puts e.backtrace
        puts "Warning: Error during generation, template may be incomplete"
      end

    end
  end

end
