# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
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
# => jruby -S rake datashift:import:csv model=<active record class> input=<file.csv>
#
namespace :datashift do

  namespace :import do

    desc "Populate a model's table in db with data from CSV file"
    task :csv, [:model, :loader, :input, :verbose] => [:environment] do |t, args|

      # in familiar ruby style args seems to have been become empty with rake 0.9.2 whatever i try
      # so had to revert back to ENV
      model = ENV['model']
      input = ENV['input']
   
      raise "USAGE: rake datashift:import:csv input=file.csv model=<Class>" unless(input)
      raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless(model)
      raise "ERROR: Could not find csv file #{args[:input]}" unless File.exists?(input)

      require 'csv_loader'
      
      begin
        # support modules e.g "Spree::Property") 
        klass = ModelMapper::class_from_string(model)  #Kernel.const_get(model)
      rescue NameError
        raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
      end

      puts "INFO: Using CSV loader"
    
      loader = DataShift::CsvLoader.new(klass)

      loader.perform_load(input)
    end
  end
  
end