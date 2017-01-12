# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  Base class for generators, which provide services to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    include DataShift::Logging

    attr_accessor :configuration

    def initialize; end

    # Prepare to generate with associations but then
    # calls a **derived generate** method i.e abstract to this base class
    #
    # file_name => Filename for generated template
    #
    def generate_with_associations(file_name, klass)

      state = DataShift::Configuration.call.with

      DataShift::Configuration.call.with = :all

      generate(file_name, klass)
    ensure
      DataShift::Configuration.call.with = state

    end

  end

end
