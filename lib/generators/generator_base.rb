# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  Base class for generators, which provide services to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    include DataShift::Logging

    attr_accessor :headers

    attr_accessor :configuration

    def initialize

      #TOFIX - don't think these belong here
      @headers = DataShift::Headers.new(:na)

      @configuration = DataShift::Exporters::Configuration.call
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_model_methods(klass)

      op_types_in_scope = configuration.op_types_in_scope

      collection = ModelMethods::Manager.catalog_class(klass)

      if collection
        model_methods = []

        collection.each { |mm| model_methods << mm if(op_types_in_scope.include? mm.operator_type) }

        DataShift::Transformer::Remove.unwanted_model_methods model_methods

        model_methods
      else
        []
      end
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_headers(klass)

      @headers = Headers.new(klass)

      headers.source_to_headers

      headers
    end


    alias klass_to_collection_and_headers klass_to_headers

    # Prepare to generate with associations but then
    # calls a **derived generate** method i.e abstract to this base class
    #
    # file_name => Filename for generated template
    #
    def generate_with_associations(file_name, klass)

      state = DataShift::Exporters::Configuration.call.with

      DataShift::Exporters::Configuration.call.with = :all

      generate(file_name, klass)
    ensure
      DataShift::Exporters::Configuration.call.with = state

    end

  end

end
