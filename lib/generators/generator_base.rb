# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  Base class for generators, which provide services to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    attr_accessor :headers, :remove_list

    attr_accessor :configuration

    def initialize
      @headers = DataShift::Headers.new(:na)
      @remove_list = []

      @configuration = DataShift::Exporters::Configuration.configuration
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_model_methods(klass)

      # default to generating just klass columns
      associations = configuration.op_types_in_scope

      collection = ModelMethods::Manager.catalog_class(klass)

      if collection
        model_methods = []
        # make sure models columns are first, then other association types
        if associations.delete(:assignment)
          collection.for_type(:assignment).each { |md| model_methods << md }
        end

        associations.each do |a|
          collection.for_type(a).each { |md| model_methods << md }
        end

        remove_list = configuration.prep_remove_list

        model_methods.delete_if { |h| remove_list.include?( h.operator.to_sym ) } unless remove_list.empty?

        model_methods
      else
        []
      end
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_headers(klass)

      # default to generating just klass columns
      associations = configuration.op_types_in_scope

      @headers = Headers.new(klass)

      collection = ModelMethods::Manager.catalog_class(klass)

      if collection

        # make sure models columns are first, then other association types
        if associations.delete(:assignment)
          collection.for_type(:assignment).each { |md| @headers << md.operator.to_s }
        end

        associations.each do |a|
          collection.for_type(a).each { |md| @headers << md.operator.to_s }
        end

        remove_headers
      end

      headers
    end

    alias klass_to_collection_and_headers klass_to_headers

    # Prepare to generate with associations but then
    # calls a **derived generate** method i.e abstract to this base class
    #
    # file_name => Filename for generated template
    #
    def generate_with_associations(file_name, klass)

      DataShift::Exporters::Configuration.configure do |config|
        config.with = [:all]
      end

      generate(file_name, klass)
    end

    # Parse options and remove  headers
    # Specify columns to remove via  lib/exporters/configuration.rb
    #
    def remove_headers
      remove_list = configuration.prep_remove_list

      headers.delete_if { |h| remove_list.include?( h.to_sym ) } unless remove_list.empty?
    end

  end

end
