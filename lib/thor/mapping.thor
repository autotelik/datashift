# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Mar 2015
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
require 'datashift'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift


  class Mapping < Thor

    include DataShift::Logging

    desc "template", "Generate a simple mappings template\nInput is treated as the *source* unless otherwise directed"

    method_option :model, :aliases => '-m', :desc => "The active record model to use for mappings"
    method_option :model_as_dest, :aliases => '-d', :type=> :boolean, :desc => "Set model attributes as destination"

    method_option :excel, :aliases => '-e', :desc => "The excel spreadsheet to use for mappings"
    method_option :excel_as_dest, :aliases => '-a', :type=> :boolean, :desc => "Set excel headers as destination"

    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"

    def template()

      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')

      result = options[:result]

      if(File.directory?(result))
        result = File.join(result, "mapping_template.yaml")
        puts "Output generated in #{result}"
      end

      logger.info "Datashift: Starting mapping template generation in #{result}"

      mapper = DataShift::MappingGenerator.new(result)

      model = options[:model]

      mappings = String.new

      mappings += mapper.generate(model, options) unless(model.nil? && options[:excel])

      mappings += mapper.generate_from_excel(options[:excel], options) if(options[:excel])

      File.open(result, 'w') { |f| f << mappings }

    end

  end

end
