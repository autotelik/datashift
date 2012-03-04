# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Mar 2012
# License::   MIT.
#
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
# => bundle exec thor datashift:generate:excel --model <active record class> --result <output_template.xls>
#

module Datashift
 
  class Generate < Thor     
                                             
    desc "excel --model <Class> --result <file.xls>", "generate a template from an active record model" 
    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"
    
    def excel()
     
     # TODO - We're assuming run from a rails app/top level dir...
     # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
     require File.expand_path('config/environment.rb')

      
     require 'excel_generator'

      model = options[:model]
      result = options[:result]
      
      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError => e
        puts e
        raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>"
      end

      gen = DataShift::ExcelGenerator.new(result)

      gen.generate(klass)
    end
  end

end
