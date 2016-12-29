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
require 'datashift/binder'
require 'datashift/querying'

module DataShift

  class LoaderBase

    include DataShift::Logging
    include DataShift::Querying

    attr_accessor :file_name
    attr_accessor :binder

    attr_accessor :doc_context

    # Fwd calls onto the DocumentContext
    extend Forwardable

    def_delegators :doc_context,
                   :load_object,
                   :loaded_count, :failed_count, :processed_object_count,
                   :headers, :reporters, :reporters=

    def initialize
      @file_name = ''

      @doc_context = DocContext.new(Object)
      @binder      = Binder.new
    end

    def setup_load_class(load_class)
      @doc_context = DocContext.new( MapperUtils.ensure_class(load_class) )
    end

    def run(file_name, load_class)
      @file_name = file_name

      setup_load_class(load_class)

      logger.info("Loading objects of type #{load_object_class}")

      # no implementation - derived classes must implement
      perform_load
    end

    # Reset the loader, including database object to be populated, and load counts
    #
    def reset(object = nil)
      doc_context.reset(object)
    end

    def abort_on_failure?
      !! DataShift::Configuration.call.abort_on_failure
    end

    def load_object_class
      doc_context.klass
    end

    def set_headers(headings)
      logger.info("Setting parsed headers to [#{headings.inspect}]")
      doc_context.headers = headings
    end

    def report
      reporters.each(&:report)
    end

    # Core API
    #
    # Returns an instance of DataShift::Binder
    #
    # Given a list of free text column names from inbound headers,
    # map all headers to a domain model containing details on operator, look ups etc.
    #
    def bind_headers( headers )

      logger.info("Binding #{headers.size} inbound headers to #{load_object_class.name}")

      @binder ||= DataShift::Binder.new

      begin
        binder.map_inbound_headers(load_object_class, headers)
      rescue => e
        logger.error("Failed to map header row to set of database operators : #{e.inspect}")
        logger.error( e.backtrace )
        raise MappingDefinitionError, 'Failed to map header row to set of database operators'
      end

      unless binder.missing_bindings.empty?
        logger.warn("Following headings couldn't be mapped to #{load_object_class}:")
        binder.missing_bindings.each { |m| logger.warn("Heading [#{m.source}] - Index (#{m.index})") }

        if DataShift::Configuration.call.strict_inbound_mapping
          raise MappingDefinitionError, "Missing mappings for columns : #{binder.missing_bindings.join(',')}"
        end

      end

      mandatory = DataShift::Mandatory.new(DataShift::Configuration.call.mandatory)

      unless mandatory.contains_all?(binder)
        mandatory.missing_columns.each do |er|
          logger.error "Mandatory column missing - expected column '#{er}'"
        end

        raise MissingMandatoryError, 'Mandatory columns missing  - see logs - please fix and retry.'
      end

      binder
    end

    # We can bind inbound 'fields' to associated model columns, from any source, not just headers
    alias bind_fields bind_headers

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
    def configure_from(yaml_file, klass = nil, locale_key = 'data_flow_schema')

      setup_load_class(klass) if(klass)

      logger.info("Reading Datashift loader config from: #{yaml_file.inspect}")

      data = YAML.load( ERB.new( IO.read(yaml_file) ).result )

      logger.info("Read Datashift config: #{data.inspect}")

      @config.merge!(data['LoaderBase']) if data['LoaderBase']

      @config.merge!(data[self.class.name]) if data[self.class.name]

      @binder ||= DataShift::Binder.new

      data_flow_schema = DataShift::DataFlowSchema.new

      # Includes configuring DataShift::Transformation
      nodes = data_flow_schema.prepare_from_file(yaml_file, locale_key)

      @binder.add_bindings_from_nodes( nodes )

      PopulatorFactory.configure(load_object_class, yaml_file)

      logger.info("Loader Options : #{@config.inspect}")
    end

  end

end
