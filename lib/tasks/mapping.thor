# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Mar 2015
# License::   MIT.
#
# Note, not DataShift, case sensitive, create namespace for command line : datashift

module Datashift

  class Mapping < DataShift::ThorExportBase

    include DataShift::Logging

    desc "template", "Generate a YAML mappings template\nInput is treated as the *source* unless otherwise directed"

    method_option :model, :aliases => '-m', :desc => "The active record model to use for mappings"
    method_option :model_as_dest, :aliases => '-d', :type=> :boolean, :desc => "Set model attributes as destination"

    method_option :excel, :aliases => '-e', :desc => "The excel spreadsheet to use for mappings"
    method_option :excel_as_dest, :aliases => '-a', :type=> :boolean, :desc => "Set excel headers as destination"

    method_option :result, :aliases => '-r', :required => true, :desc => "Create template of model in supplied file"

    def template()

      start_connections

      result = options[:result]

      if(File.directory?(result))
        result = File.join(result, "mapping_template.yaml")
        puts "Output generated in #{result}"
      end

      logger.info "Datashift: Starting mapping template generation to [#{result}]"
      
      mapper = DataShift::MappingGenerator.new

      model = options[:model]

      mappings = String.new

      # if not from Excel and no model, still generate most basic mapping possible
      mappings += mapper.generate(model, options.dup) unless(model.nil? && options[:excel])

      mappings += mapper.generate_from_excel(options[:excel], options.dup) if(options[:excel])

      File.open(result, 'w') { |f| f << mappings }

    end

  end

end
