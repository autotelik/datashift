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
      
    desc "template", "generate a simple mappings template"

    method_option :model, :aliases => '-m', :desc => "The active record model to export"
    method_option :model_as_dest, :aliases => '-d', :type=> :boolean, :desc => "Set model attributes as destination"

    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"
    
    def template()
     
      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')

      model = options[:model]
      result = options[:result]

      if(File.directory?(result))
        result = File.join(result, "mapping_template.yaml")
        puts "Output generated in #{result}"
      end

      logger.info "Datashift: Starting mapping template generation in #{result}"

      mapper = DataShift::MappingGenerator.new(result)

      mapper.generate(model, options)

    end
    
    
  end

end
