# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Mar 2016
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
#
require 'thor'
require_relative 'thor_behaviour'

require 'csv_generator'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

  class Generate  < Thor

    include DataShift::ThorBehavior

    desc "excel", "generate a template from an active record model (with optional associations)"

    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"

    def excel()
      start_connections

      generate( DataShift::ExcelGenerator.new)

      puts "Datashift: Excel Template COMPLETED to #{options[:result]}"
    end


    desc "csv", "generate a template from an active record model (with optional associations)"
    method_option :model, :aliases => '-m', :required => true, :desc => "The active record model to export"
    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"

    def csv()
      start_connections

      generate( DataShift::CsvGenerator.new)

      puts "Datashift: CSV Template COMPLETED to #{options[:result]}"
    end

    desc "db", "Generate a template for every Active Record model"

    method_option :path, :aliases => '-p', :required => true, desc: "Path in which to create export files"
    method_option :csv, :aliases => '-c', desc: "Generate CSV template instead - Excel is default."

    method_option :prefix_map, :aliases => '-x', type: :hash, :default => {},
                  desc: "For namespaced tables/models specify the table prefix to module map e.g spree_:Spree"

    method_option :modules, :aliases => '-m', type: :array, :default => [],
                  desc: "List of Modules to search for namespaced models"

    def db()

      start_connections

      unless File.directory?(options[:path])
        puts "WARNING : No such PATH found #{options[:path]} - trying mkdir"
        FileUtils::mkdir_p(options[:path])
      end

      generator = options[:csv] ?  DataShift::CsvGenerator.new :  DataShift::ExcelGenerator.new

      DataShift::Exporters::Configuration.from_hash(options)

      ext = options[:csv] ? '.csv' : '.xls'

      modules = [nil] + options[:modules]

      ActiveRecord::Base.connection.tables.each do |table|

        modules.each do |m|
          @klass = DataShift::MapperUtils.table_to_arclass(table, m)
          break if(@klass)
        end

        options[:prefix_map].each do |p, m|
          @klass = DataShift::MapperUtils.table_to_arclass(table.gsub(p, ''), m)
          break if(@klass)
        end unless(@klass)

        if(@klass.nil?)
          puts  "ERROR: No Model found for Table [#{table}] - perhaps a prefix map required?"
          next
        end

        result = File.join(options[:path], "#{table}#{ext}")

        puts "Datashift: Start export to #{result} for [#{table}]"
        begin
          if(options[:associations])
            logger.info("Datashift: Generating with associations")
            generator.generate_with_associations(result, @klass)
          else
            generator.generate(result, @klass)
          end
        rescue => e
          puts e
          puts e.backtrace
          puts "Warning: Error during export, data may be incomplete"
        end
      end

    end

    no_commands do

      def generate(generater)
        model = options[:model]
        result = options[:result]

        DataShift::Exporters::Configuration.from_hash(options)

        logger.info "Datashift: Starting template generation for #{generater.class.name} to #{result}"

        klass = DataShift::MapperUtils::class_from_string(model)  #Kernel.const_get(model)

        raise "ERROR: No such Model [#{model}] found - check valid model supplied via -model <Class>" if(klass.nil?)

        begin

          if(options[:associations])
            logger.info("Datashift: Generating template including associations")
            generater.generate_with_associations(result, klass)
          else
            generater.generate(result, klass)
          end
        rescue => e
          puts e
          puts e.backtrace
          puts "Warning: Error during export, data may be incomplete"
        end

      end

    end   # no_commands

  end

end
