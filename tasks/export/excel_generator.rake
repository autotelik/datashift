# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT.
#
# REQUIRES:   JRuby
#
# Usage::
#
#  In Rakefile:
#
#     require 'datashift'
#
#     DataShift::load_tasks
#
#  Cmd Line:
#
# => jruby -S rake datashift:generate:excel model=<active record class> result=<output_template.xls>
#
namespace :datashift do
  
  namespace :generate do
    
    include RakeUtils

    desc "Generate a template .xls (Excel) file for a model"
  
    task :excel, [:model, :result] => :environment do |t, args|
      
      
      # in familiar ruby style args seems to have been become empty using this new style for rake 0.9.2
      #  whatever format i try, on both Win and OSX .. so had to revert back to ENV
      model = args.model || ENV['model']
      result = args.result || ENV['result']
      
      RakeUtils::check_args(args, [:model, :result]) do
          x =<<-EOS
      USAGE::

        rake datashift:generate:excel model=<Class> result=<file.xls>

             Generate a template Excel file representing an Active Record mode.
             Once populated with data the template can be used to import the data,
             via the partner import tasks
             Parameters :
                [:model]  - Mandatory - The database model to export.
                [:results] - Mandatory -  Name of the output template file..
          EOS
          puts x
        end


      require 'excel_generator'
      
      raise "USAGE: jruby -S rake datashift:generate:excel model=<Class> result=<file.xls>" unless(result)


      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError
        raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
      end

      gen = DataShift::ExcelGenerator.new(result)

      gen.generate(klass)
    end

  end

  namespace :export do

    desc "Export active record data to .xls (Excel) file"

    task :excel, [:model, :result] => [:environment] do |t, args|

      require 'excel_generator'

      # in familiar ruby style args seems to have been become empty using this new style for rake 0.9.2
      #  whatever format i try, on both Win and OSX .. so had to revert back to ENV
      model = ENV['model']
      result = ENV['result']

      raise "USAGE: jruby -S rake datashift:gen:excel model=<Class> result=<file.xls>" unless(result)
      raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless(model)

      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError
        raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
      end

      gen = DataShift::ExcelGenerator.new(result)
      
      gen.export(klass.all)
    end

  end

end