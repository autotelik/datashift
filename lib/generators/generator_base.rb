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
    end


    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    def klass_to_headers(klass)

      @headers = Headers.new(klass)

      headers.source_to_headers

      DataShift::Transformer::Remove.unwanted_headers(@headers)

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
