# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
#  Details::  Base class for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with Binder classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
module DataShift

  require 'datashift/binder'
  require 'datashift/querying'

  class LoaderBase

    include DataShift::Logging
    include DataShift::Querying

    attr_reader :strict

    attr_accessor :file_name

    attr_accessor :doc_context
    attr_accessor :binder, :mandatory

    # Options
    #
    #  :strict          : Raise exceptions when issues like missing mandatory columns
    #
    def initialize
      @file_name   =  ''

      @doc_context = DocContext.new(NilClass)

      @binder      = Binder.new
      @mandatory   = Mandatory.new
    end

    # Options
    #    [:object]    : Process against an existing object, otherwise new objects created
    #    [:mandatory] : List of columns that must be present in headers
    #
    def run(file_name, object_class, options = {})

      logger.verbose if(options[:verbose])

      @strict = (options[:strict] == true)

      @file_name = file_name

      logger.info("Loading options objects of type #{load_object_class}")

      @doc_context = DocContext.new(object_class)

      @mandatory = Mandatory.new(options[:mandatory]) if options[:mandatory]

      logger.info("Loading objects of type #{load_object_class}")

      doc_context.reset(options[:object])

      # no implementation - derived classes must implement
      perform_load( options )
    end

    # Reset the loader, including database object to be populated, and load counts
    #
    def reset(object = nil)
      doc_context.reset(object)
    end

    def abort_on_failure?
      # TODO: @config[:abort_on_failure].to_s == 'true'
    end

    def loaded_count
      reporter.loaded_objects.size
    end

    def failed_count
      reporter.failed_objects.size
    end

    def load_object_class
      doc_context.klass
    end

    def load_object
      doc_context.load_object
    end

    def set_headers(column_headings)
      logger.info("Setting parsed headers to [#{column_headings.inspect}]")

      doc_context.headers = column_headings
    end

    def headers
      doc_context.headers
    end

    def reporter
      doc_context.reporter
    end

    def report
      reporter.report
    end

    # Core API
    #
    # Given a list of free text column names from inbound headers,
    # map all headers to a domain model containing details on operator, look ups etc.
    #
    # Options:
    #    [:strict]          : Raise an exception of any headers can't be mapped to an attribute/association
    #    [:ignore]          : List of column headers to ignore when building operator map
    #
    #    [:force_inclusion] : List of columns that do not map to any operator but should be includeed in processing.
    #
    #       This provides the opportunity for :
    #
    #       1) loaders to provide specific methods to handle these fields, when no direct operator
    #        is available on the model or it's associations
    #
    #       2) Handle delegated methods i.e no direct association but method is on a model throuygh it's delegate
    #
    #    [:include_all]     : Include all headers in processing - takes precedence of :force_inclusion
    #
    def bind_headers( headers, options = {} )

      logger.info("Binding #{headers.size} inbound headers to #{load_object_class.name}")

      @strict = options[:strict] if options[:strict]

      @binder ||= DataShift::Binder.new

      begin
        binder.map_inbound_headers(load_object_class, headers, options )
      rescue => e
        logger.error("Failed to map header row to set of database operators : #{e.inspect}")
        logger.error( e.backtrace )
        raise MappingDefinitionError, 'Failed to map header row to set of database operators'
      end

      unless binder.missing_bindings.empty?
        logger.warn("Following headings couldn't be mapped to #{load_object_class}:")
        binder.missing_bindings.each { |m| logger.warn("Heading [#{m.inbound_name}] - Index (#{m.inbound_index})") }

        raise MappingDefinitionError, "Missing mappings for columns : #{binder.missing_bindings.join(',')}" if strict
      end

      unless mandatory.contains_all?(binder)
        mandatory.missing_columns.each do |er|
          logger.error "Mandatory column missing - expected column '#{er}'"
        end

        raise MissingMandatoryError, 'Mandatory columns missing  - please fix and retry.'
      end

      binder
    end

    # We can bind inbound 'fields' to associatde model columns, from any source, not just headers
    alias bind_fields bind_headers

    #     # Process columns with a default value specified
    #     def process_defaults()
    #       @populator.process_defaults
    #     end
    #
    #
    #     # Core API - Given a single free text column name from a file, search method mapper for
    #     # associated operator on base object class.
    #     #
    #     # If suitable association found, process row data and then assign to current load_object
    #     def find_and_process(column_name, data)
    #
    #       puts "WARNING: MethodDictionary empty for class #{load_object_class}" unless(MethodDictionary.for?(load_object_class))
    #
    #       method_detail = MethodDictionary.find_method_detail( load_object_class, column_name )
    #
    #       if(method_detail)
    #         process(method_detail, data)
    #       else
    #         puts "No matching method found for column #{column_name}"
    #         @load_object.errors.add(:base, "No matching method found for column #{column_name}")
    #       end
    #     end

    # Any Config under key 'LoaderBase' is merged over existing options - taking precedence.
    #
    # Any Config under a key equal to the full name of the Loader class (e.g DataShift::SpreeEcom::ImageLoader)
    # is merged over existing options - taking precedence.
    #
    #  Format :
    #
    #    LoaderClass:
    #     option: value
    #
    def configure_from(yaml_file)

      logger.info("Reading Datashift loader config from: #{yaml_file.inspect}")

      data = YAML.load( ERB.new( IO.read(yaml_file) ).result )

      logger.info("Read Datashift config: #{data.inspect}")

      @config.merge!(data['LoaderBase']) if data['LoaderBase']

      @config.merge!(data[self.class.name]) if data[self.class.name]

      ContextFactory.configure(load_object_class, yaml_file)

      logger.info("Loader Options : #{@config.inspect}")
    end

    protected

    # Take current column data and split into each association
    # Supported Syntax :
    #  assoc_find_name:value | assoc2_find_name:value | etc
    def get_each_assoc
      current_value = @populator.value.to_s.split( Delimiters.multi_assoc_delim )
    end

  end

end
