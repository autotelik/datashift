# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Module for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with Binder classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
module DataShift

  module Loading


    attr_accessor :doc_context

    attr_accessor :binder


    def load_object_class
      doc_context.klass
    end


    def load_object
      doc_context.current_object
    end

    # Core API
    # 
    # Given a list of free text column names from a file, 
    # map all headers to a domain model containing details on operator, look ups etc.
    #
    # Options:
    #    [:strict]          : Raise an exception of any headers can't be mapped to an attribute/association
    #    [:ignore]          : List of column headers to ignore when building operator map
    #    [:mandatory]       : List of columns that must be present in headers
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

      mandatory = options[:mandatory] || []

      strict = (options[:strict] == true)

      @binder = DataShift::Binder.new

      begin
        binder.map_inbound_headers(load_object_class, headers, options )
      rescue => e
        puts e.inspect, e.backtrace
        logger.error("Failed to map header row to set of database operators : #{e.inspect}")
        raise MappingDefinitionError, "Failed to map header row to set of database operators"
      end

      unless(binder.missing_bindings.empty?)
        logger.warn("Following headings couldn't be mapped to #{load_object_class} \n#{binder.missing_bindings.inspect}")
        raise MappingDefinitionError, "Missing mappings for columns : #{binder.missing_bindings.join(",")}" if(strict)
      end

      unless(mandatory.empty? || binder.contains_mandatory?(mandatory) )
        binder.missing_mandatory(mandatory).each { |er| puts "ERROR: Mandatory column missing - expected column '#{er}'" }
        raise MissingMandatoryError, "Mandatory columns missing  - please fix and retry."
      end

      binder
    end

  end
end